import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/widgets/sp_fade_in.dart';

class ClickAnimation extends StatefulWidget {
  const ClickAnimation({
    super.key,
    this.onDone,
    this.top,
    this.left,
    this.bottom,
    this.right,
    this.clickDuration = const Duration(milliseconds: 500),
  });

  final void Function()? onDone;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;
  final Duration clickDuration;

  @override
  State<ClickAnimation> createState() => _ClickAnimationState();
}

class _ClickAnimationState extends State<ClickAnimation> {
  double opacity = 1.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(widget.clickDuration).then((_) {
      if (!mounted) return;

      setState(() {
        opacity = 0.0;
      });

      widget.onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      bottom: widget.bottom,
      right: widget.right,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: Durations.medium1,
          opacity: opacity,
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: buildInnerCircle(),
                  ),
                ),
                Positioned.fill(
                  child: buildOutsideCircle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOutsideCircle() {
    return SpFadeIn(
      curve: Curves.fastLinearToSlowEaseIn,
      testCurves: false,
      delay: Durations.short2,
      duration: const Duration(seconds: 1),
      child: const SizedBox.shrink(),
      builder: (context, animation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              width: 64,
              height: 64,
              transform: Matrix4.identity()..spScale(lerpDouble(0.3, 1, animation.value)!),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: lerpDouble(0, 1, animation.value)!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildInnerCircle() {
    return SpFadeIn(
      curve: Curves.fastLinearToSlowEaseIn,
      testCurves: false,
      delay: Durations.short1,
      duration: const Duration(seconds: 1),
      child: const SizedBox.shrink(),
      builder: (context, animation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              width: 30,
              height: 30,
              transform: Matrix4.identity()..spScale(lerpDouble(0.3, 1, animation.value)!),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: lerpDouble(0, 3, animation.value)!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
