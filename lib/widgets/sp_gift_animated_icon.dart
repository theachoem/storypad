import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';

class SpGiftAnimatedIcon extends StatelessWidget {
  const SpGiftAnimatedIcon({
    super.key,
    this.size,
  });

  final double? size;

  @override
  Widget build(BuildContext context) {
    return SpLoopAnimationBuilder(
      curve: Curves.ease,
      duration: Durations.long4,
      reverseDuration: Durations.long4,
      child: Icon(SpIcons.gift, color: ColorScheme.of(context).bootstrap.info.color, size: size),
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.rotate(
          angle: math.sin(value * 2 * math.pi) * 0.1,
          child: Transform.scale(
            scale: 1 + math.cos(value * 4 * math.pi) * 0.01,
            child: child,
          ),
        );
      },
    );
  }
}
