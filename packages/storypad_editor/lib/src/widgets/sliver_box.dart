import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A box holding a sliver laid out at its full length, as if all of it were on screen: sized to the sliver's scroll
/// extent, never scrolling.
///
/// For the editor's box layout: inside a scroll view, super_editor lays its document out as a sliver of that scroll
/// view. This hosts that sliver in a `Column` (or any box) of the scroll view instead -- without being a viewport
/// itself, so super_editor still finds (and scrolls, and measures against) the scroll view's own viewport. A
/// `ShrinkWrappingViewport` would be found first: it doesn't scroll, so the caret would never be brought into view.
class SliverBox extends SingleChildRenderObjectWidget {
  const SliverBox({super.key, required Widget sliver}) : super(child: sliver);

  @override
  RenderSliverBox createRenderObject(BuildContext context) => RenderSliverBox();
}

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
