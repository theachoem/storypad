import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:storypad/core/story_editor/embeds/audio_embed.dart';
import 'package:storypad/core/story_editor/embeds/media_embed.dart';
import 'package:storypad/core/story_editor/story_pad_embeds.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// A page in the storypad_editor editor, stored as Markdown (title included, as its leading heading).
///
/// A page the user didn't change serializes to the Markdown it was opened with, untouched: change detection (drafts,
/// "revert if nothing changed") compares the stored pages.
///
/// [selection] is in flat text offsets (each block's characters, 1 for an embed, plus one for its line break), which
/// survive reopening the page in a new controller (e.g. from the view screen into edit), unlike node ids.
class StoryPadEditorController {
  StoryPadEditorController({
    required String markdown,
    required TextSelection selection,
    required bool readOnly,
  }) : _originalMarkdown = markdown,
       editor = StoryEditorController(
         markdown: markdown,
         embeds: StoryPadEmbeds.all,
         readOnly: readOnly,
         unknownBuilder: StoryPadEmbeds.buildUnknown,
       ) {
    if (!selection.isCollapsed || selection.baseOffset > 0) this.selection = selection;
  }

  /// The editor itself, for the editor widget and toolbar.
  final StoryEditorController editor;

  final String _originalMarkdown;

  /// Whether [node] is the page title: a heading that's the page's first block.
  bool _isTitle(DocumentNode? node) {
    if (node is! ParagraphNode || editor.document.getNodeIndexById(node.id) != 0) return false;
    final Object? blockType = node.getMetadataValue(NodeMetadata.blockType);
    return blockType is NamedAttribution && blockType.id.startsWith('header');
  }

  /// Embeds never go into (or before) the page title: with the caret there, it moves to the title's end, so the embed
  /// goes right after the title (see `StoryEditorController.insertEmbed`) -- no empty line is added for it.
  void _moveCaretBelowTitle() {
    final selection = editor.selection.value ?? editor.lastSelection;
    final title = selection == null ? null : editor.document.getNodeById(selection.extent.nodeId);
    if (title == null || !_isTitle(title)) return;

    editor.composer.setSelectionWithReason(
      DocumentSelection.collapsed(
        position: DocumentPosition(nodeId: title.id, nodePosition: title.endPosition),
      ),
      SelectionReason.contentChange,
    );
  }

  /// The page as Markdown for storage, title included. The editor caches its Markdown per edit, so this is cheap to call
  /// on every change.
  String serialize() => editor.isDirty ? editor.toMarkdown() : _originalMarkdown;

  /// The plain text after the page title (see `StoryCodec.pageBodyOf`).
  String bodyPlainText() => StoryCodec.plainTextOf(StoryCodec.pageBodyOf(editor.document));

  // ==========================================================================
  // Selection, in flat text offsets
  // ==========================================================================

  TextSelection get selection {
    final selection = editor.selection.value ?? editor.lastSelection;
    if (selection == null) return const TextSelection.collapsed(offset: 0);
    return TextSelection(baseOffset: _offsetOf(selection.base), extentOffset: _offsetOf(selection.extent));
  }

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

  /// Inserts photos/videos (an album when there's more than one) at the caret (the last one while the editor has none,
  /// else the end), full width.
  void insertMedia(List<String> paths) => _insertBelowTitle(const MediaEmbed(), MediaValue(paths, size: EmbedSize.max));

  /// Inserts a voice note at the caret (the last one while the editor has none, else the end).
  void insertAudio(String path) => _insertBelowTitle(const AudioEmbed(), path);

  void _insertBelowTitle<T extends Object>(StoryEmbed<T> embed, T value) {
    _moveCaretBelowTitle();
    editor.insertEmbed(embed, value);
  }

  void dispose() {
    // Pages are disposed (e.g. a deleted page) while their editor widget may still be mounted for this frame; the
    // editor controller must outlive it.
    final editorToDispose = editor;
    SchedulerBinding.instance.addPostFrameCallback((_) => editorToDispose.dispose());
    SchedulerBinding.instance.ensureVisualUpdate();
  }
}
