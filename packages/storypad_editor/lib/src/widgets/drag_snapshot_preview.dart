import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures a real pixel snapshot of a dragged block (via a [RepaintBoundary]
/// wrapped around the whole document) and re-paints just that block's
/// cropped region at the current drop slot, semi-transparent — a
/// Notion-style "here's exactly what's about to land here" preview, on top
/// of (not instead of) the plain drop-indicator line both
/// [ReorderableDocumentOverlay] (desktop) and
/// [MobileReorderableDocumentOverlay] (mobile) already draw.
///
/// A real snapshot, rather than re-invoking a component builder to build a
/// second copy of the block, is what actually reproduces the block's exact
/// on-screen appearance — bold/color/links/indent and all — since
/// SuperEditor's real styling only exists by way of its own internal
/// stylesheet-application pipeline, not something re-buildable standalone
/// from outside it.
///
/// Mix into a drag-and-drop overlay's `State`: wrap the child that contains
/// the document in [wrapWithSnapshotBoundary], call [captureDragSnapshot] the
/// moment a drag starts (before anything moves — it's the last complete
/// frame of the untouched layout), [disposeDragSnapshot] when the drag ends
/// or is cancelled (also called automatically from [dispose]), and render
/// [buildSnapshotPreview] at the current drop slot while a snapshot is held.
mixin DragSnapshotPreviewMixin<T extends StatefulWidget> on State<T> {
  final _repaintBoundaryKey = GlobalKey();

  ui.Image? _snapshotImage;
  double? _snapshotPixelRatio;
  int _captureGeneration = 0;

  bool get hasDragSnapshot => _snapshotImage != null;

  Widget wrapWithSnapshotBoundary(Widget child) => RepaintBoundary(key: _repaintBoundaryKey, child: child);

  /// Captures the whole document's current appearance as an image, to later
  /// crop [buildSnapshotPreview] from. Safe to call even if the boundary
  /// isn't laid out yet (silently does nothing) — a dragged block always
  /// has *some* rect by the time a drag can start, so this only fails to
  /// capture in situations that would already have no rect to show anyway.
  Future<void> captureDragSnapshot() async {
    final boundary = _repaintBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return;
    }

    final generation = ++_captureGeneration;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    // The drag may have ended (or another started) while capturing: a late image would be stale.
    if (!mounted || generation != _captureGeneration) {
      image.dispose();
      return;
    }

    setState(() {
      _snapshotImage?.dispose();
      _snapshotImage = image;
      _snapshotPixelRatio = pixelRatio;
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
              sourceRect.left * pixelRatio,
              sourceRect.top * pixelRatio,
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
