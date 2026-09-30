import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

import '../codec/story_codec.dart';
import '../embed/story_embed.dart';
import '../embed/story_embed_codec.dart';
import '../embed/story_embed_node.dart';
import '../embed/story_embed_registry.dart';
import '../embed/unknown_embed.dart';
import 'change_text_alignment_request.dart';
import 'story_editor_actions.dart';
import 'transform_text_request.dart';
import 'update_story_embed_request.dart';

/// The one object an editor needs: it holds the document and every embed, and does everything else -- serialization,
/// formatting commands ([actions]), embed operations, focus and selection, dirty tracking, read-only.
///
/// ```dart
/// final controller = StoryEditorController(
///   embeds: [MediaEmbed(), AudioEmbed()],
///   markdown: story.body,
/// );
///
/// MarkdownEditor(controller: controller, onChanged: save);
///
/// controller.actions.toggleBold();
/// controller.insertEmbed(const AudioEmbed(), 'audio/1.m4a');
/// final markdown = controller.toMarkdown();
/// ```
///
/// The controller is created with its content; to open another story, create a new controller (and key the editor
/// with it). Content is never swapped in place, because super_editor's undo history can't be reset.
///
/// Owned by its creator, who must [dispose] it -- after the editor widget using it is gone.
class StoryEditorController extends ChangeNotifier {
  /// A controller editing [markdown], rendering [embeds]. Content no embed claims is kept by the built-in unknown
  /// embed and drawn with [unknownBuilder] (or a small default placeholder).
  ///
  /// Throws an [ArgumentError] if the embeds conflict (see [StoryEmbedRegistry]).
  StoryEditorController({
    required List<StoryEmbed> embeds,
    String markdown = '',
    bool readOnly = false,
    this.unknownBuilder,
  }) : embeds = List.unmodifiable(embeds),
       codec = StoryCodec(embeds: embeds),
       _readOnly = ValueNotifier(readOnly) {
    _document = MutableDocument(nodes: _withTrailingParagraph(codec.decodeNodes(markdown)));
    _composer = MutableDocumentComposer();
    _editor = Editor(
      editables: {Editor.documentKey: _document, Editor.composerKey: _composer},
      requestHandlers: [
        updateStoryEmbedHandler,
        changeTextAlignmentHandler,
        transformTextHandler,
        ...defaultRequestHandlers,
      ],
      reactionPipeline: [
        for (final reaction in defaultEditorReactions)
          // Re-clamps free task indent whenever any task is deleted.
          if (reaction is! UpdateSubTaskIndentAfterTaskDeletionReaction &&
              // Turns a pasted image URL into a stock ImageNode, which isn't one of the app's embeds.
              reaction is! ImageUrlConversionReaction)
            reaction,
      ],
      isHistoryEnabled: true,
    );
    actions = StoryEditorActions(this);

    _document.addListener(_onDocumentChanged);
    _composer.selectionNotifier.addListener(_onSelectionChanged);
    _composer.preferences.addListener(notifyListeners);
    focusNode.addListener(_updateToolbarActive);
    _readOnly.addListener(notifyListeners);
    _readOnly.addListener(_updateToolbarActive);

    _savedMarkdown = toMarkdown();
  }

  /// A controller for a page stored as Quill Delta [ops] (from before Markdown), converted to Markdown first -- so
  /// what's edited is exactly what will be saved. See [StoryCodec.quillToMarkdown].
  factory StoryEditorController.fromQuill(
    List<Object?> ops, {
    required List<StoryEmbed> embeds,
    bool readOnly = false,
    StoryEmbedBuilder<UnknownEmbedValue>? unknownBuilder,
  }) {
    return StoryEditorController(
      embeds: embeds,
      markdown: StoryCodec(embeds: embeds).quillToMarkdown(ops),
      readOnly: readOnly,
      unknownBuilder: unknownBuilder,
    );
  }

  /// The embeds this controller renders, in registration order.
  final List<StoryEmbed> embeds;

  /// Converts this controller's content (with its embeds) to and from Markdown and Quill.
  final StoryCodec codec;

  /// Draws content no embed claims (see [UnknownEmbedValue]). `null` uses a small default placeholder.
  final StoryEmbedBuilder<UnknownEmbedValue>? unknownBuilder;

  /// Formatting and block commands on the current selection. See [StoryEditorActions].
  late final StoryEditorActions actions;

  late final MutableDocument _document;
  late final MutableDocumentComposer _composer;
  late final Editor _editor;

  /// The embed registry: every embed plus the built-in unknown embed.
  StoryEmbedRegistry get registry => codec.registry;

  /// The underlying super_editor document. An escape hatch: prefer the controller's own API.
  MutableDocument get document => _document;

  /// The underlying super_editor composer (selection, pending styles). An escape hatch.
  MutableDocumentComposer get composer => _composer;

  /// The underlying super_editor editor, for requests the controller doesn't wrap. An escape hatch.
  Editor get editor => _editor;

  // ── Focus, selection, toolbars ─────────────────────────────────────────────

  /// The editor's focus node, owned by the controller so a toolbar can use it before (or without) the editor being
  /// built.
  final focusNode = FocusNode(debugLabel: 'StoryEditor');

  /// The tap-region group the editor belongs to. Wrap a toolbar in a `TapRegion(groupId: tapRegionGroupId)` so
  /// tapping it doesn't count as tapping outside the editor (which would unfocus it and drop the selection).
  final String tapRegionGroupId = 'story-editor-${_nextGroupId++}';

  static int _nextGroupId = 0;

  /// The current selection. Listen to it (or to the controller) to follow selection changes.
  ValueListenable<DocumentSelection?> get selection => _composer.selectionNotifier;

  /// The last non-null selection -- where [insertEmbed] inserts when the editor has lost its selection (e.g. while a
  /// picker sheet was open).
  DocumentSelection? get lastSelection => _lastSelection;
  DocumentSelection? _lastSelection;

  void _onSelectionChanged() {
    final selection = _composer.selection;
    if (selection != null) _lastSelection = selection;
    notifyListeners();
  }

  int _holds = 0;
  final _selectionHeld = ValueNotifier(false);
  final _toolbarActive = ValueNotifier(false);

  /// Whether something (e.g. a toolbar's popup) is holding the selection. On mobile, the editor normally drops its
  /// selection when it loses focus; while held, it keeps it.
  ValueListenable<bool> get isSelectionHeld => _selectionHeld;

  /// Whether an editing toolbar should be showing: the editor isn't read-only, and has focus or its selection is held
  /// (a toolbar popup is open). Drives show-on-focus mobile toolbars.
  ValueListenable<bool> get isToolbarActive => _toolbarActive;

  /// Keeps the selection while focus is elsewhere -- e.g. while a toolbar's link dialog or color menu is open --
  /// until the returned hold is released. Take it synchronously, *before* opening the route, since opening it moves
  /// focus. Holds are counted; releasing one twice is harmless.
  SelectionHold holdSelection() {
    _holds++;
    _updateToolbarActive();
    return SelectionHold._(this);
  }

  /// Runs [body] (e.g. `showDialog`) while holding the selection. See [holdSelection].
  Future<R> keepSelectionWhile<R>(Future<R> Function() body) async {
    final hold = holdSelection();
    try {
      return await body();
    } finally {
      hold.release();
    }
  }

  void _release() {
    _holds--;
    _updateToolbarActive();
  }

  void _updateToolbarActive() {
    _selectionHeld.value = _holds > 0;
    _toolbarActive.value = !_readOnly.value && (focusNode.hasFocus || _holds > 0);
  }

  // ── Read-only ──────────────────────────────────────────────────────────────

  final ValueNotifier<bool> _readOnly;

  /// Whether the editor is read-only: no typing, no editing controls on embeds, no editing toolbar
  /// ([isToolbarActive] is false). Checkboxes still toggle (that's an edit the app persists, like in StoryPad's read
  /// view). Only affects the UI: the controller's own API still edits.
  bool get readOnly => _readOnly.value;
  set readOnly(bool value) => _readOnly.value = value;

  /// [readOnly], as a listenable.
  ValueListenable<bool> get readOnlyListenable => _readOnly;

  // ── Content ────────────────────────────────────────────────────────────────

  final _revision = ValueNotifier(0);

  /// Increments on every document change -- edits, undo and redo -- but not on selection changes. Listen to this to
  /// save.
  ValueListenable<int> get documentRevision => _revision;

  // The document's own change log, not the editor's edit listener: undo/redo replay history without reporting edits
  // to editor listeners, but the document still reports that it changed.
  void _onDocumentChanged(DocumentChangeLog changeLog) {
    _revision.value++;
    notifyListeners();
  }

  String? _markdownCache;
  int _markdownCacheRevision = -1;

  /// The document as canonical Markdown. Cached until the next edit.
  String toMarkdown() {
    if (_markdownCacheRevision != _revision.value) {
      _markdownCache = codec.encode(_document);
      _markdownCacheRevision = _revision.value;
    }
    return _markdownCache!;
  }

  /// The document as plain text (for search and word counts).
  String toPlainText() => StoryCodec.plainTextOf(_document);

  late String _savedMarkdown;

  /// Whether the document differs from when it was loaded or last [markSaved] -- compared as canonical Markdown, so
  /// an edit that's undone, or content that merely wasn't canonical when loaded, isn't a change.
  bool get isDirty => toMarkdown() != _savedMarkdown;

  /// Marks the current content as saved (see [isDirty]).
  void markSaved() => _savedMarkdown = toMarkdown();

  // ── Embeds ─────────────────────────────────────────────────────────────────

  /// The embed (or the unknown embed) owning [node], if it's an embed node.
  StoryEmbedCodec? embedFor(DocumentNode node) => registry.forNode(node);

  /// Every embed of [embed]'s type, in document order, e.g. "all media in this story" for a media viewer.
  List<(String nodeId, T value)> embedsOf<T extends Object>(StoryEmbedCodec<T> embed) => [
    for (final node in _document)
      if (embed.handles(node)) (node.id, embed.valueOf(node as StoryEmbedNode)),
  ];

  /// Inserts an embed holding [value] at the caret (or the [lastSelection], or at the end), as an undoable edit, and
  /// returns its node id. In a paragraph, the embed goes before an empty paragraph, or splits a non-empty one at the
  /// caret; the caret ends up after it, in a paragraph, ready to keep typing.
  String insertEmbed<T extends Object>(StoryEmbed<T> embed, T value) {
    assert(registry.byType(embed.type) != null, '"${embed.type}" is not one of this controller\'s embeds.');

    final node = embed.createNode(value);
    final position = _insertionPosition();
    final target = position == null ? null : _document.getNodeById(position.nodeId);

    if (position != null && target is ParagraphNode) {
      _editor.execute([
        ChangeSelectionRequest(
          DocumentSelection.collapsed(position: position),
          SelectionChangeType.placeCaret,
          SelectionReason.contentChange,
        ),
        InsertNodeAtCaretRequest(node: node),
      ]);
    } else {
      final afterId = target?.id ?? _document.last.id;
      final paragraph = ParagraphNode(id: Editor.createNodeId(), text: AttributedText());
      _editor.execute([
        InsertNodeAfterNodeRequest(existingNodeId: afterId, newNode: node),
        InsertNodeAfterNodeRequest(existingNodeId: node.id, newNode: paragraph),
        ChangeSelectionRequest(
          DocumentSelection.collapsed(
            position: DocumentPosition(nodeId: paragraph.id, nodePosition: const TextNodePosition(offset: 0)),
          ),
          SelectionChangeType.placeCaret,
          SelectionReason.contentChange,
        ),
      ]);
    }
    return node.id;
  }

  /// The caret (or last selection) extent, clamped to the node's current content: the last selection may predate
  /// edits made while there was no selection.
  DocumentPosition? _insertionPosition() {
    for (final selection in [_composer.selection, _lastSelection]) {
      if (selection == null) continue;
      final node = _document.getNodeById(selection.extent.nodeId);
      if (node == null) continue;

      final position = selection.extent.nodePosition;
      if (node is TextNode && position is TextNodePosition) {
        final offset = position.offset.clamp(0, node.text.length);
        return DocumentPosition(
          nodeId: node.id,
          nodePosition: TextNodePosition(offset: offset),
        );
      }
      return node.containsPosition(position)
          ? selection.extent
          : DocumentPosition(nodeId: node.id, nodePosition: node.endPosition);
    }
    return null;
  }

  /// Replaces the value of embed [nodeId] with `transform(current)`, as an undoable edit. [transform] gets the live
  /// value. Returns `false` if there's no such [embed] node, or the value didn't change.
  bool updateEmbed<T extends Object>(StoryEmbedCodec<T> embed, String nodeId, T Function(T current) transform) {
    final node = _document.getNodeById(nodeId);
    if (node is! StoryEmbedNode || node.type != embed.type) return false;

    final current = embed.valueOf(node);
    final next = transform(current);
    if (next == current) return false;

    _editor.execute([UpdateStoryEmbedRequest(embed.replaceValue(node, next))]);
    return true;
  }

  /// Removes embed [nodeId], as an undoable edit, moving the selection off it first. Returns `false` if there's no
  /// such embed node.
  bool removeEmbed(String nodeId) {
    final node = _document.getNodeById(nodeId);
    if (node is! StoryEmbedNode) return false;

    final requests = <EditRequest>[];
    final selection = _composer.selection;
    if (selection != null && (selection.base.nodeId == nodeId || selection.extent.nodeId == nodeId)) {
      final neighbor = _document.getNodeAfterById(nodeId) ?? _document.getNodeBeforeById(nodeId);
      requests.add(
        neighbor == null
            ? const ClearSelectionRequest()
            : ChangeSelectionRequest(
                DocumentSelection.collapsed(
                  position: DocumentPosition(
                    nodeId: neighbor.id,
                    nodePosition: neighbor == _document.getNodeAfterById(nodeId)
                        ? neighbor.beginningPosition
                        : neighbor.endPosition,
                  ),
                ),
                SelectionChangeType.deleteContent,
                SelectionReason.contentChange,
              ),
      );
    }

    if (_document.nodeCount == 1) {
      // Never leave the document empty.
      requests.add(
        ReplaceNodeRequest(
          existingNodeId: nodeId,
          newNode: ParagraphNode(id: Editor.createNodeId(), text: AttributedText()),
        ),
      );
    } else {
      requests.add(DeleteNodeRequest(nodeId: nodeId));
    }
    _editor.execute(requests);
    return true;
  }

  /// A document ends with a text block, so there's always somewhere to type after a trailing embed.
  static List<DocumentNode> _withTrailingParagraph(List<DocumentNode> nodes) {
    if (nodes.isNotEmpty && nodes.last is TextNode) return nodes;
    return [...nodes, ParagraphNode(id: Editor.createNodeId(), text: AttributedText())];
  }

  // ── Editor attachment ──────────────────────────────────────────────────────

  /// Editor widgets currently using this controller.
  final _attachedEditors = <Object>{};

  /// Called by an editor widget using this controller. Only one editor widget at a time may use a controller (they
  /// would share its focus node and document layout).
  ///
  /// Checked at the end of the frame, not here: an editor moved to a new parent (e.g. a responsive layout switching
  /// from a `Row` to a `Column`) is rebuilt before the one it replaces is disposed, so two can be attached briefly.
  @internal
  void attachEditor(Object editor) {
    _attachedEditors.add(editor);
    assert(() {
      if (_attachedEditors.length > 1) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_attachedEditors.length > 1) {
            FlutterError.reportError(
              FlutterErrorDetails(
                library: 'storypad_editor',
                exception: FlutterError(
                  'This StoryEditorController is used by ${_attachedEditors.length} editor widgets at once. '
                  'Each editor needs its own controller.',
                ),
              ),
            );
          }
        });
      }
      return true;
    }());
  }

  @internal
  void detachEditor(Object editor) => _attachedEditors.remove(editor);

  @override
  void dispose() {
    assert(_attachedEditors.isEmpty, 'Dispose the editor widget before its controller.');
    _document.removeListener(_onDocumentChanged);
    _composer.selectionNotifier.removeListener(_onSelectionChanged);
    _composer.preferences.removeListener(notifyListeners);
    focusNode.removeListener(_updateToolbarActive);
    _editor.dispose();
    _composer.dispose();
    _document.dispose();
    focusNode.dispose();
    _readOnly.dispose();
    _revision.dispose();
    _selectionHeld.dispose();
    _toolbarActive.dispose();
    super.dispose();
  }
}

/// A hold on the editor's selection, from [StoryEditorController.holdSelection]. Release it when the popup closes.
final class SelectionHold {
  SelectionHold._(this._controller);

  final StoryEditorController _controller;
  bool _released = false;

  bool get isReleased => _released;

  /// Releases the hold. Safe to call more than once.
  void release() {
    if (_released) return;
    _released = true;
    _controller._release();
  }
}
