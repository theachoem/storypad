import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures a real pixel snapshot of a dragged block (the block's region of a
/// [RepaintBoundary] wrapped around the whole document) and re-paints it at
/// the current drop slot, semi-transparent — a
/// Notion-style "here's exactly what's about to land here" preview, on top
/// of (not instead of) the plain drop-indicator line
/// [ReorderableDocumentOverlay] already draws.
///
/// A real snapshot, rather than re-invoking a component builder to build a
/// second copy of the block, is what actually reproduces the block's exact
/// on-screen appearance — bold/color/links/indent and all — since
/// SuperEditor's real styling only exists by way of its own internal
/// stylesheet-application pipeline, not something re-buildable standalone
/// from outside it.
///
/// Mix into a drag-and-drop overlay's `State`: wrap the child that contains
/// the document in [wrapWithSnapshotBoundary], call [captureDragSnapshot] with
/// the dragged blocks' rect the moment a drag starts (before anything moves — it's the last complete
/// frame of the untouched layout), [disposeDragSnapshot] when the drag ends
/// or is cancelled (also called automatically from [dispose]), and render
/// [buildSnapshotPreview] at the current drop slot while a snapshot is held.
mixin DragSnapshotPreviewMixin<T extends StatefulWidget> on State<T> {
  final _repaintBoundaryKey = GlobalKey();

  ui.Image? _snapshotImage;
  double? _snapshotPixelRatio;
  Offset _snapshotOrigin = Offset.zero;
  int _captureGeneration = 0;

  bool get hasDragSnapshot => _snapshotImage != null;

  Widget wrapWithSnapshotBoundary(Widget child) => _SnapshotBoundary(key: _repaintBoundaryKey, child: child);

  /// Captures [region] of the document (the dragged blocks' rect, in the
  /// coordinate space of [wrapWithSnapshotBoundary]'s child) as an image, for
  /// [buildSnapshotPreview]. Only that region: a whole document can be taller
  /// than a GPU texture may be (16384 px on Metal — a long story at 2x), which
  /// Impeller fails on. A region too large even so is captured at a lower
  /// pixel ratio (see [dragSnapshotPixelRatio]).
  ///
  /// Safe to call even if the boundary isn't laid out or painted yet
  /// (silently does nothing, and the drag shows no preview).
  Future<void> captureDragSnapshot(Rect region) async {
    final boundary = _repaintBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! _RenderSnapshotBoundary || !boundary.hasSize || boundary.debugNeedsPaint) {
      return;
    }

    final bounds = region.intersect(Offset.zero & boundary.size);
    final pixelRatio = dragSnapshotPixelRatio(bounds.size, MediaQuery.of(context).devicePixelRatio);
    if (pixelRatio == null) return;

    final generation = ++_captureGeneration;
    final image = await boundary.toImageOf(bounds, pixelRatio: pixelRatio);
    // The drag may have ended (or another started) while capturing: a late image would be stale.
    if (!mounted || generation != _captureGeneration) {
      image.dispose();
      return;
    }

    setState(() {
      _snapshotImage?.dispose();
      _snapshotImage = image;
      _snapshotPixelRatio = pixelRatio;
      _snapshotOrigin = bounds.topLeft;
    });
  }

  void disposeDragSnapshot() {
    _captureGeneration++; // Invalidates a capture still in flight.
    if (_snapshotImage == null) {
      return;
    }
    final image = _snapshotImage!;
    _snapshotImage = null;
    _snapshotPixelRatio = null;
    // Deferred a frame: this commonly runs from inside the same setState
    // that clears drag state and triggers a rebuild — disposing before that
    // rebuild has painted one last frame without the image risks disposing
    // an image mid-paint.
    WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
  }

  @override
  void dispose() {
    _snapshotImage?.dispose();
    super.dispose();
  }

  /// Renders the region of the captured snapshot corresponding to
  /// [sourceRect] (the dragged block's rect *at the moment of capture*, in
  /// the same coordinate space as [wrapWithSnapshotBoundary]'s child),
  /// stretched to fill [targetRect] (the current drop slot).
  Widget buildSnapshotPreview({required Rect sourceRect, required Rect targetRect, double opacity = 0.4}) {
    final image = _snapshotImage;
    final pixelRatio = _snapshotPixelRatio;
    if (image == null || pixelRatio == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fromRect(
      rect: targetRect,
      child: IgnorePointer(
        child: CustomPaint(
          size: targetRect.size,
          painter: _SnapshotRegionPainter(
            image: image,
            sourceRect: Rect.fromLTWH(
              (sourceRect.left - _snapshotOrigin.dx) * pixelRatio,
              (sourceRect.top - _snapshotOrigin.dy) * pixelRatio,
              sourceRect.width * pixelRatio,
              sourceRect.height * pixelRatio,
            ),
            opacity: opacity,
          ),
        ),
      ),
    );
  }
}

class _SnapshotRegionPainter extends CustomPainter {
  _SnapshotRegionPainter({required this.image, required this.sourceRect, required this.opacity});

  final ui.Image image;
  final Rect sourceRect;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final destRect = Offset.zero & size;
    // `Paint.color`'s alpha, not a separate `Opacity` widget: `drawImageRect`
    // has no ancestor render tree for `Opacity` to apply to — this is the
    // standard way to draw part of an `Image` at reduced opacity directly.
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(image, sourceRect, destRect, paint);
  }

  @override
  bool shouldRepaint(_SnapshotRegionPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.sourceRect != sourceRect || oldDelegate.opacity != opacity;
}

/// The longest side, in pixels, a drag snapshot is captured at: well within every GPU's texture limit (Metal's is
/// 16384; some Android GPUs' 4096), and plenty for a translucent preview.
const maxDragSnapshotExtent = 4096.0;

/// The pixel ratio to capture a region of [size] at: [devicePixelRatio], lowered so its longest side stays within
/// [maxDragSnapshotExtent]; `null` when there's nothing to capture.
double? dragSnapshotPixelRatio(Size size, double devicePixelRatio) {
  if (size.isEmpty || devicePixelRatio <= 0) return null;
  final longest = size.longestSide * devicePixelRatio;
  return longest <= maxDragSnapshotExtent ? devicePixelRatio : devicePixelRatio * maxDragSnapshotExtent / longest;
}

/// A [RepaintBoundary] that can capture just part of what it painted ([RenderRepaintBoundary.toImage] captures all of
/// it).
class _SnapshotBoundary extends RepaintBoundary {
  const _SnapshotBoundary({super.key, super.child});

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) => _RenderSnapshotBoundary();
}

class _RenderSnapshotBoundary extends RenderRepaintBoundary {
  /// [bounds] (in this render object's coordinates) of what was last painted, as an image.
  Future<ui.Image> toImageOf(Rect bounds, {required double pixelRatio}) {
    final offsetLayer = layer! as OffsetLayer;
    return offsetLayer.toImage(bounds, pixelRatio: pixelRatio);
  }
}
