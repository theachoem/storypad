import 'dart:math';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_extension.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';

class SpGradientLoading extends StatelessWidget {
  const SpGradientLoading({
    super.key,
    required this.height,
    required this.width,
  });

  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SpLoopAnimationBuilder(
      duration: Duration(milliseconds: 500 + max(300, Random().nextInt(800))),
      reverseDuration: Duration(milliseconds: 800 + max(0, Random().nextInt(500))),
      builder: (context, value, child) {
        return Container(
          height: height ?? 56,
          width: height ?? 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                    ColorScheme.of(context).surface.darken(0.05), ColorScheme.of(context).surface.darken(0.1), value)!,
                Color.lerp(
                    ColorScheme.of(context).surface.darken(0.1), ColorScheme.of(context).surface.darken(0.05), value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}
