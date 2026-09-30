import 'dart:ui' show Color, TextAlign;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:super_editor/super_editor.dart';

import '../controller/change_text_alignment_request.dart';
import '../embed/quill_embed_op.dart';
import '../embed/story_embed_registry.dart';
import '../embed/unknown_embed.dart';
import '../markdown/markdown_format.dart';
import '../markdown/markdown_reader.dart';
import 'quill_exporter.dart';

/// Imports Quill Delta ops into document nodes. `QuillExporter` is the reverse, for readers built on Quill.
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
/// - **The exporter's own keys**: `{"divider": …}` is a horizontal rule, and `{"sp-markdown": line}` is one line of
///   this package's Markdown (content with no Quill form), read back exactly.
///
/// Never throws on malformed ops: ops that aren't well-formed inserts are skipped.
class QuillImporter {
  QuillImporter(this.registry);

  final StoryEmbedRegistry registry;
  late final _markdown = MarkdownReader(registry);

  List<DocumentNode> import(List<Object?> ops) {
    final document = MutableDocument.empty();
    final composer = MutableDocumentComposer();
    final editor = Editor(
      editables: {Editor.documentKey: document, Editor.composerKey: composer},
      requestHandlers: [changeTextAlignmentHandler, ...defaultRequestHandlers],
      reactionPipeline: [],
    );

    try {
      final spuriousParagraphs = <String>{};
      parseQuillDeltaOps(
        sanitize(ops),
        customEditor: editor,
        blockFormats: const [QuillBlockFormat()],
        // Quotes are merged afterwards, only where lines share their format (see _mergeQuotes).
        blockMergeRules: const [MergeBlock(codeAttribution)],
        inlineFormats: _inlineFormats,
        embedBlockFormats: [_EmbedFormat(registry, _markdown, spuriousParagraphs)],
      );

      // A spurious paragraph is removed whenever it's still empty -- even if the embed line's `\n` gave it
      // formatting (e.g. alignment), which only applied to that line.
      final nodes = [
        for (final node in document)
          if (!(spuriousParagraphs.contains(node.id) && node is ParagraphNode && node.text.toPlainText().isEmpty)) node,
      ];
      // Quill's mandatory final "\n" terminates the last line; the empty paragraph it opens isn't content.
      if (nodes.length > 1 && isEmptyParagraph(nodes.last)) nodes.removeLast();
      return _mergeQuotes(nodes);
    } finally {
      editor.dispose();
      composer.dispose();
      document.dispose();
    }
  }

  /// Consecutive quote lines are one quote in Quill: merges them into one block (joined by line breaks), as
  /// super_editor's parser would -- but only lines sharing their alignment and indent, so none is lost.
  static List<DocumentNode> _mergeQuotes(List<DocumentNode> nodes) {
    final merged = <DocumentNode>[];
    for (final node in nodes) {
      final previous = merged.lastOrNull;
      if (_isQuote(node) &&
          previous != null &&
          _isQuote(previous) &&
          textAlignOf(node) == textAlignOf(previous) &&
          (node as ParagraphNode).indent == (previous as ParagraphNode).indent) {
        merged[merged.length - 1] = previous.copyParagraphWith(
          text: previous.text.copyAndAppend(AttributedText('\n')).copyAndAppend(node.text),
        );
      } else {
        merged.add(node);
      }
    }
    return merged;
  }

  static bool _isQuote(DocumentNode node) =>
      node is ParagraphNode && node.getMetadataValue(NodeMetadata.blockType) == blockquoteAttribution;

  /// Keeps well-formed insert ops only, and splits text inserts so that every `\n` is its own op. Quill compacts
  /// consecutive lines with the same block attributes into one op (e.g. two empty list items become
  /// `{"insert": "\n\n", "attributes": {"list": "bullet"}}`), but super_editor applies block formats once per op.
  static List<Map<String, Object?>> sanitize(List<Object?> ops) {
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
        // Normalize line endings: a \r would otherwise stay inside a line.
        final text = insert.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        for (final match in RegExp(r'\n|[^\n]+').allMatches(text)) {
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

    // Any line but code can be aligned.
    final align = switch (attributes['align']) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => null,
    };
    if (align != null && kind != _Kind.code) requests.add(ChangeTextAlignmentRequest(nodeId, align));

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
  _EmbedFormat(this.registry, this.markdown, this.spuriousParagraphs);

  final StoryEmbedRegistry registry;
  final MarkdownReader markdown;
  final Set<String> spuriousParagraphs;

  @override
  List<EditRequest>? applyTo(Operation operation, Editor editor) {
    final data = operation.data;
    if (data is! Map) return null;

    final insert = Map<String, Object?>.from(data);
    final attributes = Map<String, Object?>.from(operation.attributes ?? const {});
    final node =
        _exporterNode(insert) ??
        _embedNode(insert, attributes) ??
        registry.unknown.createNode(
          UnknownQuillEmbed({'insert': insert, if (attributes.isNotEmpty) 'attributes': attributes}),
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
        existingNodeId: node.id,
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

extension on _EmbedFormat {
  /// A node written under one of [QuillExporter]'s own keys, or `null`.
  DocumentNode? _exporterNode(Map<String, Object?> insert) {
    if (insert.containsKey(QuillExporter.dividerKey)) return HorizontalRuleNode(id: Editor.createNodeId());

    final line = insert[QuillExporter.markdownKey];
    if (line is! String) return null;
    // Exactly one block, or it isn't what the exporter wrote: the unknown embed keeps the op instead.
    final nodes = markdown.readLines([line]);
    return nodes.length == 1 ? nodes.single : null;
  }

  /// The node from the first registered embed importing one of the op's keys, or `null` if none does (or it rejects
  /// the op).
  DocumentNode? _embedNode(Map<String, Object?> insert, Map<String, Object?> attributes) {
    for (final key in insert.keys) {
      final embed = registry.byQuillKey(key);
      if (embed == null) continue;
      return embed.nodeFromQuill(QuillEmbedOp(key: key, insert: insert, attributes: attributes));
    }
    return null;
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
