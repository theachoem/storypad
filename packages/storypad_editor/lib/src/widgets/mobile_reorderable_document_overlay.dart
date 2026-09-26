import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';
import 'drag_snapshot_preview.dart';

/// Notion-style long-press-to-reorder for touch, where there's no room for a
/// separate drag handle the way [ReorderableDocumentOverlay] (desktop's
/// hover-revealed one) uses: long-pressing anywhere on a block — not a
/// dedicated handle — activates it (shown with a soft highlight behind it),
/// and dragging from there reorders it, the same way as on desktop.
///
/// Only active while [enabled] — [RawEditor] only sets that `true` once the
/// editor's [FocusNode] has lost focus, since a plain tap needs to keep
/// meaning "place the caret and start editing" while actively editing.
/// While enabled, this covers every block with an opaque gesture region, so
/// a plain tap on a block also has to be re-implemented here (in
/// [_handleTap]) exactly as SuperEditor's own tap-to-focus would have done,
/// since that region physically sits in front of SuperEditor's own gesture
/// detection and would otherwise swallow the tap.
///
/// Embeds are the exception: their region is translucent and doesn't handle
/// taps, so an embed's own buttons (play, open, resize, …) work on the first
/// tap even while the editor is unfocused, while long-press still reorders.
class MobileReorderableDocumentOverlay extends StatefulWidget {
  const MobileReorderableDocumentOverlay({
    super.key,
    required this.document,
    required this.editor,
    required this.editorOps,
    required this.focusNode,
    required this.documentLayoutResolver,
    required this.enabled,
    required this.child,
  });

  final Document document;
  final Editor editor;
  final CommonEditorOperations editorOps;

  /// Given focus after a plain tap on a block — see [_handleTap]. This is
  /// the same [FocusNode] passed to `SuperEditor.focusNode`; requesting
  /// focus on it is what actually opens the keyboard and resumes normal
  /// editing (`insertCaretAtPosition` alone only moves the selection, it
  /// doesn't touch focus).
  final FocusNode focusNode;

  final DocumentLayout Function() documentLayoutResolver;
  final bool enabled;
  final Widget child;

  @override
  State<MobileReorderableDocumentOverlay> createState() => _MobileReorderableDocumentOverlayState();
}

class _MobileReorderableDocumentOverlayState extends State<MobileReorderableDocumentOverlay>
    with DragSnapshotPreviewMixin {
  final _stackKey = GlobalKey();

  /// The node currently held (long-pressed), or `null` when nothing is being
  /// dragged.
  String? _draggingNodeId;

  /// The dragged node's own natural (not full-row-stretched — see
  /// [_visualRectForNode]) rect, captured once when the drag starts — the
  /// source region [buildSnapshotPreview] crops its pixels from.
  Rect? _draggedNodeSourceRect;

  /// Offset from the long-press's down position to [_draggedNodeSourceRect]'s
  /// top-left, captured once at drag start — see the matching field on
  /// [ReorderableDocumentOverlay] for why: it's what lets the floating
  /// preview keep the same relative grab point as it follows the finger.
  Offset? _grabOffset;

  /// The pointer's current position, in this overlay's own local coordinate
  /// space — see the matching field on [ReorderableDocumentOverlay].
  Offset? _pointerPosition;

  /// A snapshot of every *other* node's on-screen rect, taken once when the
  /// drag starts — see the matching field on [ReorderableDocumentOverlay]
  /// for why a snapshot instead of live-querying on every move.
  List<MapEntry<String, Rect>> _dragRects = const [];

  /// Index into [_dragRects] where the dragged node would land if dropped
  /// right now.
  int? _dropIndex;

  /// Rebuilds on every document edit (including this overlay's own
  /// `MoveNodeRequest` from a completed drag) — *twice*: once synchronously
  /// (scheduling a rebuild for the current frame) and once more a frame
  /// later via [_scheduleFollowUpRebuild]. Both matter. Without the first,
  /// nothing here reacts to the document changing at all. The second is
  /// less obvious but just as necessary: this overlay is an *ancestor* of
  /// `SuperEditor` in the tree (it wraps `widget.child`), and Flutter builds
  /// dirty elements parent-before-child within a frame — so our rebuild
  /// (computing every node's rect via `documentLayoutResolver()`) runs
  /// *before* SuperEditor's own internal presenter has re-laid-out for the
  /// new node order in that same frame, using stale positions. Nothing else
  /// then triggers a second rebuild here to pick up the now-correct layout
  /// — that's exactly the gap that let a long-press started right after a
  /// reorder mark the wrong block as held, even after `pumpAndSettle`.
  late final FunctionalEditListener _editListener;

  void _scheduleFollowUpRebuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _editListener = FunctionalEditListener((_) {
      // `_safeSetState`, not a plain guarded `setState`: `_endDrag` (a drag
      // gesture callback, which per `_safeSetState`'s own doc comment can
      // in principle fire mid-rebuild) executes a `MoveNodeRequest`
      // synchronously, which notifies this very listener before `_endDrag`
      // returns -- so this can run in exactly the same locked-tree
      // situation `_safeSetState` exists to guard against.
      _safeSetState(() {});
      _scheduleFollowUpRebuild();
    });
    widget.editor.addListener(_editListener);
    // The very first build always runs before `widget.child` (the
    // SuperEditor whose document layout `_rectForNode` reads) has been
    // inflated and mounted, so every node's gesture region is necessarily
    // skipped that first time — see `_rectForNode`'s comment. This forces
    // one guaranteed extra build right after the first frame, by which
    // point the layout exists and every region gets its real rect.
    _scheduleFollowUpRebuild();
  }

  @override
  void dispose() {
    widget.editor.removeListener(_editListener);
    super.dispose();
  }

  /// Calls [setState] normally, except when a frame is already mid-build/
  /// layout/paint, when it defers to a post-frame callback instead.
  ///
  /// [_buildNodeGestureRegion] keys each gesture region by node id (see its
  /// own doc comment) specifically so a reorder tears down and rebuilds
  /// regions rather than reusing them -- but that means an *edit or focus
  /// change that lands while a drag is active* (e.g. something elsewhere
  /// requesting focus, which flips [enabled] to `false` on this overlay's
  /// very next rebuild) can remove the currently-held node's own
  /// `GestureDetector` mid-gesture. Flutter's gesture recognizers invoke
  /// their pending `onLongPressCancel`/`onLongPressEnd` *synchronously* as
  /// part of that disposal -- which happens *during* the very rebuild that
  /// triggered it, while the widget tree is locked. Calling `setState`
  /// directly from [_cancelDrag] (or any of the other drag callbacks, which
  /// carry the same risk in principle) in that situation throws "setState()
  /// or markNeedsBuild() called when widget tree was locked."
  void _safeSetState(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(fn);
        }
      });
      return;
    }
    setState(fn);
  }

  RenderBox? get _stackBox => _stackKey.currentContext?.findRenderObject() as RenderBox?;

  Rect? _rectForNode(String nodeId) {
    // Unlike ReorderableDocumentOverlay (desktop), which only ever computes a
    // rect lazily in response to an actual pointer event — always strictly
    // after the first frame — this widget builds a gesture region for every
    // node on every build, including the very first one, before
    // `widget.child` (the SuperEditor whose documentLayoutKey this resolver
    // reads) has been inflated into the element tree and populated that key.
    // `documentLayoutResolver()` doing a hard `as DocumentLayout` cast on the
    // still-null state at that point is a routine "not laid out yet" case
    // here, not a real error — the next frame (once SuperEditor has mounted)
    // resolves it, so this simply skips this node's region for now.
    DocumentLayout layout;
    try {
      layout = widget.documentLayoutResolver();
    } catch (_) {
      return null;
    }

    final component = layout.getComponentByNodeId(nodeId);
    final stackBox = _stackBox;
    if (component == null || stackBox == null || !stackBox.attached) {
      return null;
    }

    final renderBox = (component as State).context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return null;
    }

    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: stackBox);
    // The full stack width, not the component's own (possibly narrow, for a
    // short line) width — so the whole row is a tap/long-press target, the
    // same "tap anywhere on the row" leniency Notion's mobile editor gives.
    return Rect.fromLTWH(0, topLeft.dy, stackBox.size.width, renderBox.size.height);
  }

  /// The node's own natural rect (not stretched to the full row width the
  /// way [_rectForNode] is, for gesture-hit-testing leniency) — what the
  /// drop indicator line and [buildSnapshotPreview]'s source/target actually
  /// need, so a short line's preview isn't stretched across the whole row.
  Rect? _visualRectForNode(String nodeId) {
    DocumentLayout layout;
    try {
      layout = widget.documentLayoutResolver();
    } catch (_) {
      return null;
    }

    final component = layout.getComponentByNodeId(nodeId);
    final stackBox = _stackBox;
    if (component == null || stackBox == null || !stackBox.attached) {
      return null;
    }

    final renderBox = (component as State).context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return null;
    }

    return renderBox.localToGlobal(Offset.zero, ancestor: stackBox) & renderBox.size;
  }

  void _handleTap(String nodeId, TapUpDetails details) {
    final docLayout = widget.documentLayoutResolver();
    final docOffset = docLayout.getDocumentOffsetFromAncestorOffset(details.globalPosition);
    final tapPosition = docLayout.getDocumentPositionNearestToOffset(docOffset);
    if (tapPosition != null) {
      widget.editorOps.insertCaretAtPosition(tapPosition);
    }
    widget.focusNode.requestFocus();
  }

  void _startDrag(String nodeId, LongPressStartDetails details) {
    final rects = <MapEntry<String, Rect>>[];
    var originalIndex = 0;
    for (final node in widget.document) {
      if (node.id == nodeId) {
        continue;
      }
      final rect = _rectForNode(node.id);
      if (rect != null) {
        rects.add(MapEntry(node.id, rect));
        if (widget.document.getNodeIndexById(node.id) < widget.document.getNodeIndexById(nodeId)) {
          originalIndex++;
        }
      }
    }

    final sourceRect = _visualRectForNode(nodeId);
    final stackBox = _stackBox;
    final downPosition = stackBox?.globalToLocal(details.globalPosition);

    _safeSetState(() {
      _draggingNodeId = nodeId;
      _draggedNodeSourceRect = sourceRect;
      _grabOffset = sourceRect == null || downPosition == null ? null : downPosition - sourceRect.topLeft;
      _pointerPosition = downPosition;
      _dragRects = rects;
      _dropIndex = originalIndex;
    });
    // Fire-and-forget — see the matching call in ReorderableDocumentOverlay's
    // own `_startDrag` for why this is safe to not await here.
    captureDragSnapshot();
  }

  int _computeDropIndex(double pointerY) {
    for (int i = 0; i < _dragRects.length; i++) {
      final rect = _dragRects[i].value;
      if (pointerY < rect.top + rect.height / 2) {
        return i;
      }
    }
    return _dragRects.length;
  }

  double? _yForDropIndex(int index) {
    if (_dragRects.isEmpty) {
      return null;
    }
    if (index >= _dragRects.length) {
      return _dragRects.last.value.bottom;
    }
    return _dragRects[index].value.top;
  }

  void _updateDrag(LongPressMoveUpdateDetails details) {
    final stackBox = _stackBox;
    if (stackBox == null) {
      return;
    }
    final localPosition = stackBox.globalToLocal(details.globalPosition);
    _safeSetState(() {
      _pointerPosition = localPosition;
      _dropIndex = _computeDropIndex(localPosition.dy);
    });
  }

  void _endDrag(LongPressEndDetails details) {
    final nodeId = _draggingNodeId;
    final targetIndex = _dropIndex;
    disposeDragSnapshot();
    _safeSetState(() {
      _draggingNodeId = null;
      _draggedNodeSourceRect = null;
      _grabOffset = null;
      _pointerPosition = null;
      _dragRects = const [];
      _dropIndex = null;
    });

    if (nodeId == null || targetIndex == null) {
      return;
    }
    widget.editor.execute([MoveNodeRequest(nodeId: nodeId, newIndex: targetIndex)]);
  }

  void _cancelDrag() {
    disposeDragSnapshot();
    _safeSetState(() {
      _draggingNodeId = null;
      _draggedNodeSourceRect = null;
      _grabOffset = null;
      _pointerPosition = null;
      _dragRects = const [];
      _dropIndex = null;
    });
  }

  Widget _buildNodeGestureRegion(String nodeId) {
    final rect = _rectForNode(nodeId);
    if (rect == null) {
      return const SizedBox.shrink();
    }

    // An embed's region only claims long-press (reorder): taps fall through to the embed's own widgets.
    final isEmbed = widget.document.getNodeById(nodeId) is StoryEmbedNode;

    return Positioned.fromRect(
      // Without this, Flutter reconciles this list of regions by *position*
      // (there's nothing else distinguishing one `Positioned` from another),
      // not by node identity: after a reorder, whatever region used to sit
      // at a given list position gets reused — GestureDetector, recognizer,
      // and all — for whatever node is now at that position, instead of
      // being torn down and rebuilt fresh. That reuse is exactly what let a
      // long-press starting right after a reorder land on a recognizer
      // still wired (at some layer Flutter doesn't fully refresh on a mere
      // rebuild) to the *previous* occupant of that position, marking the
      // wrong block as held.
      key: ValueKey(nodeId),
      rect: rect,
      child: GestureDetector(
        behavior: isEmbed ? HitTestBehavior.translucent : HitTestBehavior.opaque,
        onTapUp: isEmbed ? null : (details) => _handleTap(nodeId, details),
        onLongPressStart: (details) => _startDrag(nodeId, details),
        onLongPressMoveUpdate: _updateDrag,
        onLongPressEnd: _endDrag,
        onLongPressCancel: _cancelDrag,
      ),
    );
  }

  Widget _buildHeldHighlight() {
    final rect = _rectForNode(_draggingNodeId!);
    if (rect == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fromRect(
      rect: rect.deflate(2),
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// The rect of whichever node sits at [dropIndex] once the drag completes
  /// (or the last node's rect if [dropIndex] is past the end) — used to size
  /// and position the drop indicator line to match that specific block's
  /// exact width/left, not a generic fixed inset, so the line always lines
  /// up with whichever block it's actually attached to.
  Rect? _neighborVisualRectAtDropIndex(int dropIndex) {
    if (_dragRects.isEmpty) {
      return null;
    }
    final neighborId = dropIndex >= _dragRects.length ? _dragRects.last.key : _dragRects[dropIndex].key;
    return _visualRectForNode(neighborId);
  }

  Widget _buildDropIndicator() {
    final dropIndex = _dropIndex;
    if (dropIndex == null) {
      return const SizedBox.shrink();
    }
    final y = _yForDropIndex(dropIndex);
    final neighborRect = _neighborVisualRectAtDropIndex(dropIndex);
    if (y == null || neighborRect == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: neighborRect.left,
      width: neighborRect.width,
      top: y - 1,
      child: IgnorePointer(child: Container(height: 2, color: Theme.of(context).colorScheme.primary)),
    );
  }

  /// The semi-transparent, real preview of the dragged block — a floating
  /// ghost that tracks the finger freely in both x and y (via
  /// [_pointerPosition]/[_grabOffset]), on top of (not instead of)
  /// [_buildDropIndicator]'s plain line, which still only snaps vertically
  /// between slots. See the matching doc comment on
  /// [ReorderableDocumentOverlay]'s own `_buildDragPreview` for the full
  /// rationale — this is purely cosmetic; [_dropIndex] (driven only by
  /// vertical position) is what actually decides where the block lands.
  Widget _buildDragPreview() {
    final sourceRect = _draggedNodeSourceRect;
    final pointerPosition = _pointerPosition;
    final grabOffset = _grabOffset;
    if (sourceRect == null || pointerPosition == null || grabOffset == null || !hasDragSnapshot) {
      return const SizedBox.shrink();
    }

    final topLeft = pointerPosition - grabOffset;
    return buildSnapshotPreview(
      sourceRect: sourceRect,
      targetRect: Rect.fromLTWH(topLeft.dx, topLeft.dy, sourceRect.width, sourceRect.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        wrapWithSnapshotBoundary(widget.child),
        if (widget.enabled)
          for (final node in widget.document) _buildNodeGestureRegion(node.id),
        if (_draggingNodeId != null) _buildHeldHighlight(),
        if (_draggingNodeId != null) _buildDropIndicator(),
        if (_draggingNodeId != null) _buildDragPreview(),
      ],
    );
  }
}
