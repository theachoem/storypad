import 'dart:math';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';

class SpGradientLoading extends StatelessWidget {
  const SpGradientLoading({
    super.key,
    required this.height,
    required this.width,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SpLoopAnimationBuilder(
      duration: Duration(milliseconds: 500 + max(300, Random().nextInt(800))),
      reverseDuration: Duration(milliseconds: 800 + max(0, Random().nextInt(500))),
      builder: (context, value, child) {
        return Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                    ColorScheme.of(context).readOnly.surface2, ColorScheme.of(context).readOnly.surface5, value)!,
                Color.lerp(
                    ColorScheme.of(context).readOnly.surface3, ColorScheme.of(context).readOnly.surface1, value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}
