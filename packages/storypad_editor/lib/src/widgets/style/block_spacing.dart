import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Space above and below one block, outside any frame it has (see [StoryBlockStyle] for the space inside one).
@immutable
final class BlockSpacing {
  const BlockSpacing.only({this.top = 0, this.bottom = 0});

  const BlockSpacing.all(double space) : top = space, bottom = space;

  static const zero = BlockSpacing.only();

  final double top;
  final double bottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlockSpacing && top == other.top && bottom == other.bottom;

  @override
  int get hashCode => Object.hash(top, bottom);

  @override
  String toString() => 'BlockSpacing(top: $top, bottom: $bottom)';
}
