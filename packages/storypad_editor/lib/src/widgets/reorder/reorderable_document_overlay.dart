import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../controller/move_blocks.dart';
import 'drag_snapshot_preview_mixin.dart';

/// Wraps [child] (the rendered document, e.g. a [SuperEditor]) with
/// Notion-style drag handles: hovering the mouse over a block reveals a small
/// grip icon floating in the left gutter, and dragging it reorders that block
/// anywhere else in the document.
///
/// The handle is a floating overlay, not a layout change — it's absolutely
/// positioned in the space left of each block (the editor's left padding, as
/// the app set it), shrinking to fit when that's narrow (see
/// [ReorderableDocumentOverlay.handleSizeFor]), so hovering never resizes or reflows the text.
///
/// Dragging the handle of a block inside the selection moves every block the selection touches, together (select
/// several lines, then drag any of them); any other block's handle moves just that block.
///
/// Desktop/web only: [RawEditor] only mounts this where it also mounts its
/// other mouse-only chrome (the right-click menu) — showing/hiding the handle
/// relies on hover, which touch platforms don't have.
class ReorderableDocumentOverlay extends StatefulWidget {
  const ReorderableDocumentOverlay({
    super.key,
    required this.document,
    required this.composer,
    required this.editor,
    required this.documentLayoutResolver,
    required this.child,
  });

  final Document document;
  final DocumentComposer composer;
  final Editor editor;
  final DocumentLayout Function() documentLayoutResolver;
  final Widget child;

  @override
  State<ReorderableDocumentOverlay> createState() => _ReorderableDocumentOverlayState();

  static const _handleIconSize = 14.0;

  static const _handleGap = 4.0;

  static const _minHandleIconSize = 10.0;

  static const _minHandleGap = 1.0;

  /// The drag handle's icon size and its gap to the text, given [space] left of the block: full size (14 + 4) when it
  /// fits; with less, the gap shrinks first, then the icon (not below 10).
  static ({double icon, double gap}) handleSizeFor(double space) {
    if (space >= _handleIconSize + _handleGap) return (icon: _handleIconSize, gap: _handleGap);
    if (space >= _handleIconSize + _minHandleGap) return (icon: _handleIconSize, gap: space - _handleIconSize);
    final icon = (space - _minHandleGap).clamp(_minHandleIconSize, _handleIconSize);
    return (icon: icon, gap: _minHandleGap);
  }
}

class _ReorderableDocumentOverlayState extends State<ReorderableDocumentOverlay> with DragSnapshotPreviewMixin {
  final _stackKey = GlobalKey();

  /// The node currently under the mouse, while nothing is being dragged.
  String? _hoveredNodeId;

  /// The node whose handle is being dragged, or `null` when no drag is in progress.
  String? _draggingNodeId;

  /// Every node being dragged, in document order: [_draggingNodeId] alone, or every block the selection touches when
  /// it's one of them.
  List<String> _draggedNodeIds = const [];

  /// The dragged nodes' rect, captured once when the drag starts —
  /// alongside [captureDragSnapshot], gives [buildSnapshotPreview] both the
  /// pixels and the source region to crop them from.
  Rect? _draggedNodeSourceRect;

  /// Offset from the drag's down position to [_draggedNodeSourceRect]'s
  /// top-left, captured once at drag start — lets the floating preview (see
  /// [_buildDragPreview]) track the pointer while keeping the same relative
  /// grab point throughout the drag, the same way a real dragged object
  /// would, instead of snapping its whole rect under the pointer.
  Offset? _grabOffset;

  /// The pointer's current position, in this overlay's own local coordinate
  /// space — updated on every pan update so the preview can follow it
  /// freely in both x and y (Notion-style), independently of
  /// [_dropIndex]/[_dragRects], which still only track vertical slot
  /// snapping for the drop *line* and the eventual move's target.
  Offset? _pointerPosition;

  /// A snapshot of every *other* node's on-screen rect, taken once when the
  /// drag starts. Rects don't change mid-drag (nothing moves until the drag
  /// completes), so this avoids re-querying the document layout on every
  /// `onPanUpdate`.
  List<MapEntry<String, Rect>> _dragRects = const [];

  /// Index into [_dragRects] where the dragged node would land if dropped
  /// right now — i.e. the index [MoveBlocks.requests] takes, since
  /// [_dragRects] already excludes the dragged node the same way the
  /// document does internally when it's removed-then-reinserted.
  int? _dropIndex;

  RenderBox? get _stackBox => _stackKey.currentContext?.findRenderObject() as RenderBox?;

  Rect? _rectForNode(String nodeId) {
    final component = widget.documentLayoutResolver().getComponentByNodeId(nodeId);
    final stackBox = _stackBox;
    if (component == null || stackBox == null || !stackBox.attached) {
      return null;
    }

    final renderBox = (component as State).context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return null;
    }

    // `ancestor: stackBox` makes this return the offset in the stack's own
    // local coordinate space directly, matching what `Positioned` expects.
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: stackBox);
    return topLeft & renderBox.size;
  }

  void _handleHover(PointerHoverEvent event) {
    final stackBox = _stackBox;
    if (stackBox == null) {
      return;
    }
    final localY = stackBox.globalToLocal(event.position).dy;

    String? foundId;
    for (final node in widget.document) {
      final rect = _rectForNode(node.id);
      if (rect != null && localY >= rect.top && localY < rect.bottom) {
        foundId = node.id;
        break;
      }
    }

    if (foundId != _hoveredNodeId) {
      setState(() => _hoveredNodeId = foundId);
    }
  }

  void _handleExit(PointerExitEvent event) {
    if (_draggingNodeId == null && _hoveredNodeId != null) {
      setState(() => _hoveredNodeId = null);
    }
  }

  /// What dragging [nodeId]'s handle moves: every block the selection touches if [nodeId] is one of them, else just it.
  List<String> _draggedIdsFor(String nodeId) {
    final selection = widget.composer.selection;
    if (selection != null) {
      final selected = [for (final node in widget.document.getNodesInside(selection.base, selection.extent)) node.id];
      if (selected.contains(nodeId)) return selected;
    }
    return [nodeId];
  }

  void _startDrag(String nodeId, DragStartDetails details) {
    final draggedIds = _draggedIdsFor(nodeId);
    final dragged = draggedIds.toSet();
    final firstIndex = widget.document.getNodeIndexById(draggedIds.first);

    final rects = <MapEntry<String, Rect>>[];
    var originalIndex = 0;
    Rect? sourceRect;
    for (final node in widget.document) {
      final rect = _rectForNode(node.id);
      if (rect == null) continue;
      if (dragged.contains(node.id)) {
        sourceRect = sourceRect == null ? rect : sourceRect.expandToInclude(rect);
        continue;
      }
      rects.add(MapEntry(node.id, rect));
      if (widget.document.getNodeIndexById(node.id) < firstIndex) {
        originalIndex++;
      }
    }

    final stackBox = _stackBox;
    final downPosition = stackBox?.globalToLocal(details.globalPosition);

    setState(() {
      _draggingNodeId = nodeId;
      _draggedNodeIds = draggedIds;
      _draggedNodeSourceRect = sourceRect;
      _grabOffset = sourceRect == null || downPosition == null ? null : downPosition - sourceRect.topLeft;
      _pointerPosition = downPosition;
      _dragRects = rects;
      _dropIndex = originalIndex;
    });
    // Fire-and-forget: captures asynchronously, then setState's itself once
    // the image is ready (a frame or two later) — the plain drop-indicator
    // line is already showing by then, so the preview just fades in on top
    // of it slightly after the drag visibly starts, rather than blocking it.
    if (sourceRect != null) captureDragSnapshot(sourceRect);
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

  /// The rect of whichever node sits at [index] once the drag completes, or
  /// the last node's rect if [index] is past the end — used to both
  /// position the drop indicator's line and match its horizontal span to
  /// the actual text column (which may be centered/constrained rather than
  /// flush with this overlay's own bounds).
  Rect? _rectNearDropIndex(int index) {
    if (_dragRects.isEmpty) {
      return null;
    }
    return _dragRects[index >= _dragRects.length ? _dragRects.length - 1 : index].value;
  }

  void _updateDrag(DragUpdateDetails details) {
    final stackBox = _stackBox;
    if (stackBox == null) {
      return;
    }
    final localPosition = stackBox.globalToLocal(details.globalPosition);
    setState(() {
      _pointerPosition = localPosition;
      _dropIndex = _computeDropIndex(localPosition.dy);
    });
  }

  void _endDrag(DragEndDetails details) {
    final nodeIds = _draggedNodeIds;
    final targetIndex = _dropIndex;
    disposeDragSnapshot();
    setState(() {
      _draggingNodeId = null;
      _draggedNodeIds = const [];
      _draggedNodeSourceRect = null;
      _grabOffset = null;
      _pointerPosition = null;
      _dragRects = const [];
      _dropIndex = null;
    });

    if (nodeIds.isEmpty || targetIndex == null) {
      return;
    }
    final requests = MoveBlocks.requests(widget.document, nodeIds, targetIndex);
    if (requests.isNotEmpty) widget.editor.execute(requests);
  }

  void _cancelDrag() {
    disposeDragSnapshot();
    setState(() {
      _draggingNodeId = null;
      _draggedNodeIds = const [];
      _draggedNodeSourceRect = null;
      _grabOffset = null;
      _pointerPosition = null;
      _dragRects = const [];
      _dropIndex = null;
    });
  }

  Widget _buildHandle(String nodeId, {required bool isActive}) {
    final rect = _rectForNode(nodeId);
    if (rect == null) {
      return const SizedBox.shrink();
    }

    // The handle lives in the space left of the block (the editor's left padding), never over the text and never
    // outside the editor (where it would be clipped and out of the pointer's reach): full size when there's room,
    // shrunk to fit when there isn't.
    final size = ReorderableDocumentOverlay.handleSizeFor(rect.left);

    return Positioned(
      // Anchored to the block's own rendered left edge, not a fixed offset —
      // blocks can be indented or framed.
      left: (rect.left - size.gap - size.icon).clamp(0.0, double.infinity),
      top: rect.top,
      height: rect.height,
      width: size.icon,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          onPanStart: (details) => _startDrag(nodeId, details),
          onPanUpdate: _updateDrag,
          onPanEnd: _endDrag,
          onPanCancel: _cancelDrag,
          child: Center(
            child: Icon(
              Icons.drag_indicator,
              size: size.icon,
              // From the theme, so it shows on a dark background too.
              color: isActive
                  ? ColorScheme.of(context).primary
                  : ColorScheme.of(context).onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropIndicator() {
    final dropIndex = _dropIndex;
    final rect = dropIndex == null ? null : _rectNearDropIndex(dropIndex);
    if (rect == null || dropIndex == null) {
      return const SizedBox.shrink();
    }
    final y = dropIndex >= _dragRects.length ? rect.bottom : rect.top;

    return Positioned(
      left: rect.left,
      width: rect.width,
      top: y - 1,
      child: IgnorePointer(child: Container(height: 2, color: ColorScheme.of(context).primary)),
    );
  }

  /// The semi-transparent, real preview of the dragged block — a
  /// Notion-style floating ghost that tracks the pointer freely in both x
  /// and y (via [_pointerPosition]/[_grabOffset]), on top of (not instead
  /// of) [_buildDropIndicator]'s plain line, which still only snaps
  /// vertically between slots. The two are deliberately decoupled: this
  /// preview is cosmetic — it doesn't affect where the block actually drops
  /// (still purely [_dropIndex], driven only by vertical position) — while
  /// the line is what actually communicates that.
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
    return MouseRegion(
      onHover: _handleHover,
      onExit: _handleExit,
      child: Stack(
        key: _stackKey,
        children: [
          wrapWithSnapshotBoundary(widget.child),
          if (_draggingNodeId != null)
            _buildHandle(_draggingNodeId!, isActive: true)
          else if (_hoveredNodeId != null)
            _buildHandle(_hoveredNodeId!, isActive: false),
          if (_draggingNodeId != null) _buildDropIndicator(),
          if (_draggingNodeId != null) _buildDragPreview(),
        ],
      ),
    );
  }
}
