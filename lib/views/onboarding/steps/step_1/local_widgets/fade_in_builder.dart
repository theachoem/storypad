part of '../onboarding_step_1_view.dart';

class _FadeInBuilder extends StatelessWidget {
  const _FadeInBuilder({
    required this.child,
    required this.transformBuilder,
    this.duration = const Duration(seconds: 1),
  });

  final Widget child;
  final Duration duration;
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
