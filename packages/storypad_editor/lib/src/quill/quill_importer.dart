import 'dart:ui' show Color, TextAlign;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/quill_embed_op.dart';
import '../embed/story_embed_registry.dart';
import '../embed/unknown_embed.dart';
import '../markdown/markdown_format.dart';

/// Imports Quill Delta ops into document nodes. Import only: nothing in this package writes Quill.
///
/// Built on super_editor's Quill parser, with this package's own formats:
///
/// - **Embeds** go to the embed importing their insert key (`quillKeys`); anything unclaimed, or rejected by its
///   embed, is kept whole (attributes included) by the unknown embed. super_editor's stock embed formats (image,
///   video, audio, file) are not used: every embed is the app's to define.
/// - **One combined block format** reads header, list/task, quote, code, indent and alignment together. super_editor
///   applies only the first matching block format per line, so stock formats lose combinations (e.g. a list item's
///   indent, or an indented, aligned paragraph).
/// - **Tolerant inline formats.** Stock color/link/script formats throw on an unexpected value, which would abort the
///   whole import; here a bad value just drops that one format.
/// - **Cleanup.** The empty paragraph super_editor inserts after every embed (which then absorbs the embed line's
///   `\n`) is removed, so embeds don't gain blank lines.
///
/// Never throws on malformed ops: ops that aren't well-formed inserts are skipped.
class QuillImporter {
  QuillImporter(this.registry);

  final StoryEmbedRegistry registry;

  List<DocumentNode> import(List<Object?> ops) {
    final document = MutableDocument.empty();
    final composer = MutableDocumentComposer();
    final editor = Editor(
      editables: {Editor.documentKey: document, Editor.composerKey: composer},
      requestHandlers: List.from(defaultRequestHandlers),
      reactionPipeline: [],
    );

    try {
      final spuriousParagraphs = <String>{};
      parseQuillDeltaOps(
        _sanitize(ops),
        customEditor: editor,
        blockFormats: const [QuillBlockFormat()],
        inlineFormats: _inlineFormats,
        embedBlockFormats: [_EmbedFormat(registry, spuriousParagraphs)],
      );

      // A spurious paragraph is removed whenever it's still empty -- even if the embed line's `\n` gave it
      // formatting (e.g. alignment), which only applied to that line.
      final nodes = [
        for (final node in document)
          if (!(spuriousParagraphs.contains(node.id) && node is ParagraphNode && node.text.toPlainText().isEmpty)) node,
      ];
      // Quill's mandatory final "\n" terminates the last line; the empty paragraph it opens isn't content.
      if (nodes.length > 1 && isEmptyParagraph(nodes.last)) nodes.removeLast();
      return nodes;
    } finally {
      editor.dispose();
      composer.dispose();
      document.dispose();
    }
  }

  /// Keeps well-formed insert ops only, and splits text inserts so that every `\n` is its own op. Quill compacts
  /// consecutive lines with the same block attributes into one op (e.g. two empty list items become
  /// `{"insert": "\n\n", "attributes": {"list": "bullet"}}`), but super_editor applies block formats once per op.
  static List<Map<String, Object?>> _sanitize(List<Object?> ops) {
    final result = <Map<String, Object?>>[];
    for (final op in ops) {
      if (op is! Map) continue;

      final insert = op['insert'];
      final attributes = op['attributes'];
      if (attributes != null && attributes is! Map) continue;
      final cleanAttributes = attributes == null ? null : Map<String, Object?>.from(attributes);

      if (insert is Map) {
        result.add({'insert': Map<String, Object?>.from(insert), 'attributes': ?cleanAttributes});
      } else if (insert is String && insert.isNotEmpty) {
        for (final match in RegExp(r'\n|[^\n]+').allMatches(insert)) {
          result.add({'insert': match[0]!, 'attributes': ?cleanAttributes});
        }
      }
    }
    return result;
  }

  static const _inlineFormats = <InlineDeltaFormat>[
    _FlagFormat('bold', boldAttribution),
    _FlagFormat('italic', italicsAttribution),
    _FlagFormat('underline', underlineAttribution),
    _FlagFormat('strike', strikethroughAttribution),
    _FlagFormat('code', codeAttribution),
    _ColorFormat('color', background: false),
    _ColorFormat('background', background: true),
    _ScriptFormat(),
    _LinkFormat(),
  ];
}

/// Header, list/task, quote and code, plus indent and alignment, from one line's `\n` attributes -- all of them
/// together, unlike super_editor's stock formats, of which only the first match applies.
class QuillBlockFormat implements BlockDeltaFormat {
  const QuillBlockFormat();

  static const _keys = {'header', 'list', 'blockquote', 'code-block', 'align', 'indent'};

  @override
  List<EditRequest>? applyTo(Operation operation, Editor editor) {
    final attributes = operation.attributes;
    if (attributes == null || !attributes.keys.any(_keys.contains)) return null;

    final nodeId = editor.context.composer.selection!.extent.nodeId;
    final list = attributes['list'];
    final header = attributes['header'];
    final requests = <EditRequest>[];

    final _Kind kind;
    if (_isSet(attributes['code-block'])) {
      kind = _Kind.code;
      requests.add(ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: codeAttribution));
    } else if (list == 'checked' || list == 'unchecked') {
      kind = _Kind.task;
      requests.add(ConvertParagraphToTaskRequest(nodeId: nodeId, isComplete: list == 'checked'));
    } else if (list == 'bullet' || list == 'ordered') {
      kind = _Kind.listItem;
      requests.add(
        ConvertParagraphToListItemRequest(
          nodeId: nodeId,
          type: list == 'ordered' ? ListItemType.ordered : ListItemType.unordered,
        ),
      );
    } else if (header is int && header >= 1 && header <= 6) {
      kind = _Kind.paragraph;
      requests.add(ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: headerAttribution(header)));
    } else if (_isSet(attributes['blockquote'])) {
      kind = _Kind.paragraph;
      requests.add(ChangeParagraphBlockTypeRequest(nodeId: nodeId, blockType: blockquoteAttribution));
    } else {
      kind = _Kind.paragraph;
    }

    // Clamped: this comes straight from stored JSON, and a huge value would otherwise mean that many requests.
    final indent = _intValue(attributes['indent']).clamp(0, maxIndent);
    if (indent > 0) {
      switch (kind) {
        case _Kind.task:
          requests.add(SetTaskIndentRequest(nodeId, indent));
        case _Kind.listItem:
          requests.addAll([for (var i = 0; i < indent; i++) IndentListItemRequest(nodeId: nodeId)]);
        case _Kind.paragraph:
          requests.add(SetParagraphIndentRequest(nodeId, level: indent));
        case _Kind.code:
          break;
      }
    }

    // Alignment only exists on paragraphs (super_editor's alignment command assumes a ParagraphNode).
    final align = switch (attributes['align']) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => null,
    };
    if (align != null && kind == _Kind.paragraph) {
      requests.add(ChangeParagraphAlignmentRequest(nodeId: nodeId, alignment: align));
    }

    return requests;
  }

  static bool _isSet(Object? value) => value != null && value != false;

  static int _intValue(Object? value) => switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value) ?? 0,
    _ => 0,
  };
}

enum _Kind { paragraph, listItem, task, code }

/// Inserts every embed op through the registry: the embed importing its key, or the unknown embed. Mirrors
/// super_editor's `StandardEmbedBlockDeltaFormat`, but records the empty paragraph it inserts after the embed (to
/// hold the caret for the next op) so the importer can remove it afterwards.
class _EmbedFormat implements BlockDeltaFormat {
  _EmbedFormat(this.registry, this.spuriousParagraphs);

  final StoryEmbedRegistry registry;
  final Set<String> spuriousParagraphs;

  @override
  List<EditRequest>? applyTo(Operation operation, Editor editor) {
    final data = operation.data;
    if (data is! Map) return null;

    final insert = Map<String, Object?>.from(data);
    final attributes = Map<String, Object?>.from(operation.attributes ?? const {});
    final nodeId = Editor.createNodeId();

    DocumentNode? node;
    for (final key in insert.keys) {
      final embed = registry.byQuillKey(key);
      if (embed == null) continue;
      node = embed.nodeFromQuill(
        QuillEmbedOp(key: key, insert: insert, attributes: attributes),
        id: nodeId,
      );
      break;
    }
    node ??= registry.unknown.createNode(
      UnknownQuillEmbed({'insert': insert, if (attributes.isNotEmpty) 'attributes': attributes}),
      id: nodeId,
    );

    final document = editor.context.document;
    final caretNodeId = editor.context.composer.selection!.extent.nodeId;
    final caretNode = document.getNodeById(caretNodeId);
    final paragraphId = Editor.createNodeId();
    spuriousParagraphs.add(paragraphId);

    return [
      // An embed normally starts on a fresh empty line: take its place. Only a plain paragraph, so an embed can
      // never swallow an (empty) list item or task along with its type.
      if (caretNode != null && isEmptyParagraph(caretNode))
        ReplaceNodeRequest(existingNodeId: caretNodeId, newNode: node)
      else
        InsertNodeAfterNodeRequest(existingNodeId: caretNodeId, newNode: node),
      InsertNodeAfterNodeRequest(
        existingNodeId: nodeId,
        newNode: ParagraphNode(id: paragraphId, text: AttributedText()),
      ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(nodeId: paragraphId, nodePosition: const TextNodePosition(offset: 0)),
        ),
        SelectionChangeType.insertContent,
        SelectionReason.contentChange,
      ),
    ];
  }
}

class _FlagFormat implements InlineDeltaFormat {
  const _FlagFormat(this.name, this.attribution);

  final String name;
  final Attribution attribution;

  @override
  Attribution? from(Operation operation) => operation.attributes?[name] == true ? attribution : null;
}

/// Quill colors are `#rrggbb` or `#aarrggbb` (alpha first). Anything else is ignored.
class _ColorFormat implements InlineDeltaFormat {
  const _ColorFormat(this.name, {required this.background});

  final String name;
  final bool background;

  @override
  Attribution? from(Operation operation) {
    final value = operation.attributes?[name];
    if (value is! String) return null;

    final match = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').firstMatch(value.trim());
    if (match == null) return null;

    final hex = match[1]!;
    final color = Color(int.parse(hex, radix: 16) + (hex.length == 6 ? 0xFF000000 : 0));
    return background ? BackgroundColorAttribution(color) : ColorAttribution(color);
  }
}

class _ScriptFormat implements InlineDeltaFormat {
  const _ScriptFormat();

  @override
  Attribution? from(Operation operation) => switch (operation.attributes?['script']) {
    'super' => const ScriptAttribution.superscript(),
    'sub' => const ScriptAttribution.subscript(),
    _ => null,
  };
}

class _LinkFormat implements InlineDeltaFormat {
  const _LinkFormat();

  @override
  Attribution? from(Operation operation) {
    final value = operation.attributes?['link'];
    if (value is! String || value.isEmpty) return null;
    return LinkAttribution(value, Uri.tryParse(value));
  }
}
