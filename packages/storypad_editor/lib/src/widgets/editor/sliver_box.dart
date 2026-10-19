import 'package:flutter/widgets.dart';
import 'render_sliver_box.dart';

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
