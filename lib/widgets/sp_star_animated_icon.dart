import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';

class SpShakeAnimatedIcon extends StatelessWidget {
  const SpShakeAnimatedIcon({
    super.key,
    required this.iconData,
    this.size,
    this.color,
  });

  final double? size;
  final IconData iconData;
  final Color? color;

  factory SpShakeAnimatedIcon.star({double? size, Color? color}) {
    return SpShakeAnimatedIcon(
      size: size,
      color: color,
      iconData: SpIcons.star,
    );
  }

  static Widget gift({
    double? size,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        return SpShakeAnimatedIcon(
          size: size,
          color: color ?? ColorScheme.of(context).bootstrap.info.color,
          iconData: SpIcons.gift,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpLoopAnimationBuilder(
      curve: Curves.ease,
      duration: Durations.long4,
      reverseDuration: Durations.long4,
      child: Icon(iconData, color: color, size: size),
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
