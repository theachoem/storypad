import 'package:flutter/material.dart';

class SpSliverStickyDivider extends SliverPersistentHeaderDelegate {
  static Widget sliver() => SliverPersistentHeader(delegate: SpSliverStickyDivider._(), pinned: true);

  SpSliverStickyDivider._();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Divider(height: 1);

  @override
  double get maxExtent => 1;

  @override
  double get minExtent => 1;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
