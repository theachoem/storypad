import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_embeds.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// A page body in the storypad_editor editor, while stories are still stored as Quill Delta.
///
/// Loads Quill → Markdown → the editor, and saves back Markdown → Quill ([serialize]). A page the user didn't change
/// serializes to its original JSON, untouched: change detection (drafts, "revert if nothing changed") compares the
/// stored JSON, so a converted-but-unedited page would otherwise count as an edit.
///
/// Text offsets ([selection], [replaceText]) count like Quill's: each block's characters (1 for an embed) plus one for
/// its line break.
class StoryPadEditorRichTextController extends RichTextController {
  StoryPadEditorRichTextController({
    required List<dynamic> json,
    required TextSelection selection,
    required bool readOnly,
  }) : _originalJson = json,
       editor = StoryEditorController.fromQuill(
         json,
         embeds: storyPadEmbeds,
         readOnly: readOnly,
         unknownBuilder: buildStoryPadUnknownEmbed,
       ) {
    _logImportLosses(json);
    editor.documentRevision.addListener(notifyListeners);
    if (!selection.isCollapsed || selection.baseOffset > 0) this.selection = selection;
  }

  /// The editor itself, for the editor widget and toolbar.
  final StoryEditorController editor;

  final List<dynamic> _originalJson;

  List<dynamic>? _serialized;
  int? _serializedRevision;

  /// Formatting the conversion can't keep shouldn't exist (a real-backup audit found none), so report any that does.
  static void _logImportLosses(List<dynamic> json) {
    final losses = storyPadCodec.quillImportLosses(json);
    if (losses.isEmpty) return;
    AppLogger.error(
      'StoryPadEditorRichTextController: formatting dropped on import: ${losses.map((loss) => loss.kind.name).toSet()}',
      tag: 'StoryPadEditorRichTextController',
    );
  }

  @override
  RichTextDocument get document => StoryPadEditorRichTextDocument._(this);

  @override
  bool get readOnly => editor.readOnly;

  @override
  List<dynamic> serialize() {
    if (!editor.isDirty) return _originalJson;

    final revision = editor.documentRevision.value;
    if (_serializedRevision != revision) {
      _serialized = storyPadCodec.markdownToQuill(editor.toMarkdown());
      _serializedRevision = revision;
    }
    return _serialized!;
  }

  @override
  String getPlainText() => editor.toPlainText();

  // ==========================================================================
  // Selection, in Quill-style offsets
  // ==========================================================================

  @override
  TextSelection get selection {
    final selection = editor.selection.value ?? editor.lastSelection;
    if (selection == null) return const TextSelection.collapsed(offset: 0);
    return TextSelection(baseOffset: _offsetOf(selection.base), extentOffset: _offsetOf(selection.extent));
  }

  @override
  set selection(TextSelection value) {
    editor.composer.setSelectionWithReason(
      DocumentSelection(base: _positionAt(value.baseOffset), extent: _positionAt(value.extentOffset)),
      SelectionReason.contentChange,
    );
  }

  /// A block's length in offsets, not counting its line break.
  static int _lengthOf(DocumentNode node) => node is TextNode ? node.text.length : 1;

  int _offsetOf(DocumentPosition position) {
    var offset = 0;
    for (final node in editor.document) {
      if (node.id == position.nodeId) {
        final nodePosition = position.nodePosition;
        return offset +
            switch (nodePosition) {
              TextNodePosition() => nodePosition.offset,
              UpstreamDownstreamNodePosition() => nodePosition.affinity == TextAffinity.upstream ? 0 : 1,
              _ => 0,
            };
      }
      offset += _lengthOf(node) + 1;
    }
    return offset;
  }

  DocumentPosition _positionAt(int offset) {
    var start = 0;
    for (final node in editor.document) {
      final length = _lengthOf(node);
      if (offset <= start + length) {
        final local = (offset - start).clamp(0, length);
        return DocumentPosition(
          nodeId: node.id,
          nodePosition: node is TextNode
              ? TextNodePosition(offset: local)
              : (local == 0
                    ? const UpstreamDownstreamNodePosition.upstream()
                    : const UpstreamDownstreamNodePosition.downstream()),
        );
      }
      start += length + 1;
    }
    final last = editor.document.last;
    return DocumentPosition(nodeId: last.id, nodePosition: last.endPosition);
  }

  // ==========================================================================
  // Editing
  // ==========================================================================

  @override
  void replaceText(int index, int length, Object data, TextSelection? textSelection) {
    final start = _positionAt(index);
    final requests = <EditRequest>[
      if (length > 0)
        DeleteContentRequest(
          documentRange: DocumentRange(start: start, end: _positionAt(index + length)),
        ),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(position: start),
        SelectionChangeType.placeCaret,
        SelectionReason.contentChange,
      ),
    ];
    editor.editor.execute(requests);

    if (data is Map && data.isNotEmpty) {
      final key = '${data.keys.first}';
      final value = data.values.first;
      insertEmbed(embedType: key, value: '$value');
    } else if (data is String && data.isNotEmpty) {
      final caret = editor.selection.value?.extent;
      if (caret != null) {
        editor.editor.execute([InsertPlainTextAtCaretRequest(data)]);
      }
    }
    if (textSelection != null) selection = textSelection;
  }

  @override
  void insertEmbed({required String embedType, required String value, Map<String, dynamic>? attributes}) {
    final embed = editor.registry.byQuillKey(embedType);
    if (embed is! StoryEmbed) {
      AppLogger.error('$runtimeType#insertEmbed: no embed imports "$embedType"', tag: '$runtimeType');
      return;
    }

    final op = QuillEmbedOp.of(embedType, value, attributes: {...?attributes});
    final embedValue = embed.fromQuill(op);
    if (embedValue == null) {
      AppLogger.error('$runtimeType#insertEmbed: "$embedType" rejected $value', tag: '$runtimeType');
      return;
    }
    editor.insertEmbed(embed, embedValue);
  }

  @override
  void replaceEmbed({required int offset, required int length, required String embedType, required String value}) {
    final position = _positionAt(offset);
    final node = editor.document.getNodeById(position.nodeId);
    final embed = editor.registry.byQuillKey(embedType);
    if (node is! StoryEmbedNode || embed == null || embed.type != node.type) return;

    // Keep the embed's other properties (e.g. alignment): read the new value through Quill with them.
    final current = embed.toQuillOf(node);
    final updated = embed.fromQuill(QuillEmbedOp.of(embedType, value, attributes: current?.attributes ?? const {}));
    if (updated == null) return;
    editor.updateEmbed(embed, node.id, (_) => updated);
  }

  @override
  void moveCursorLeft() => editor.actions.moveCaret(forward: false);

  @override
  void moveCursorRight() => editor.actions.moveCaret(forward: true);

  @override
  void dispose() {
    editor.documentRevision.removeListener(notifyListeners);
    // Pages are disposed (e.g. a deleted page) while their editor widget may still be mounted for this frame; the
    // editor controller must outlive it.
    final editorToDispose = editor;
    SchedulerBinding.instance.addPostFrameCallback((_) => editorToDispose.dispose());
    SchedulerBinding.instance.ensureVisualUpdate();
    super.dispose();
  }
}

/// A [StoryPadEditorRichTextController]'s document, as the app reads it.
class StoryPadEditorRichTextDocument implements RichTextDocument {
  StoryPadEditorRichTextDocument._(this._controller);

  final StoryPadEditorRichTextController _controller;

  @override
  int get length => _controller.editor.document.fold(0, (sum, node) => sum + _lengthOf(node) + 1);

  static int _lengthOf(DocumentNode node) => node is TextNode ? node.text.length : 1;

  @override
  List<dynamic> toJson() => _controller.serialize();

  @override
  String toPlainText() => _controller.getPlainText();
}
