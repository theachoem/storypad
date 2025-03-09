import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_fade_in.dart';

class FadeInBuilder extends StatelessWidget {
  const FadeInBuilder({
    super.key,
    required this.child,
    required this.transformBuilder,
    this.curve = Curves.fastEaseInToSlowEaseOut,
    this.duration = const Duration(seconds: 1),
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Matrix4? Function(Animation<double> animation) transformBuilder;

  @override
  Widget build(BuildContext context) {
    return SpFadeIn(
      curve: Curves.fastEaseInToSlowEaseOut,
      testCurves: false,
      delay: null,
      duration: duration,
      child: child,
      builder: (context, animation, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            return Container(
              transform: transformBuilder(animation),
              child: child!,
            );
          },
        );
      },
    );
  }
}
