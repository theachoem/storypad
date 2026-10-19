import 'package:flutter/rendering.dart';

class RenderSliverBox extends RenderBox with RenderObjectWithChildMixin<RenderSliver> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) child.parentData = SliverPhysicalParentData();
  }

  @override
  void performLayout() {
    final sliver = child;
    if (sliver == null) {
      size = constraints.smallest;
      return;
    }

    assert(constraints.hasBoundedWidth, 'SliverBox needs a bounded width.');
    sliver.layout(
      SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0,
        precedingScrollExtent: 0,
        overlap: 0,
        remainingPaintExtent: double.infinity,
        crossAxisExtent: constraints.maxWidth,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: double.infinity,
        remainingCacheExtent: double.infinity,
        cacheOrigin: 0,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(constraints.maxWidth, sliver.geometry!.scrollExtent));
    _lastHeight = size.height;
  }

  double _lastHeight = 0;

  /// A sliver can't be measured without laying it out, so this answers with the last laid-out height (0 before the
  /// first layout) -- enough for an ancestor that merely asks (e.g. a dialog measuring its content).
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return constraints.constrain(Size(constraints.maxWidth, _lastHeight));
  }

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final sliver = child;
    if (sliver != null && sliver.geometry!.visible) context.paintChild(sliver, offset);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // The sliver is painted at this box's origin.
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final sliver = child;
    if (sliver == null || !sliver.geometry!.visible) return false;
    return sliver.hitTest(
      SliverHitTestResult.wrap(result),
      mainAxisPosition: position.dy,
      crossAxisPosition: position.dx,
    );
  }
}
