import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/onboarding_view.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class SpOnboardingWrappper extends StatefulWidget {
  const SpOnboardingWrappper({
    super.key,
    required this.child,
  });

  final Widget child;

  static void close(BuildContext context) {
    context.findAncestorStateOfType<_SpOnboardingWrappperState>()?.close();
  }

  @override
  State<SpOnboardingWrappper> createState() => _SpOnboardingWrappperState();
}

class _SpOnboardingWrappperState extends State<SpOnboardingWrappper> with TickerProviderStateMixin {
  AnimationController? onboardingAnimationController;
  AnimationController? homeAnimationController;

  final transitionDuration = Duration(milliseconds: 750);

  bool onboarding = false;
  bool onboarded = false;

  @override
  void initState() {
    super.initState();

    if (!onboarded) {
      onboardingAnimationController = AnimationController(vsync: this, duration: transitionDuration, value: 1.0);
      homeAnimationController = AnimationController(vsync: this, duration: transitionDuration, value: 0.0);
    }
  }

  Future<void> close() async {
    onboardingAnimationController?.reverse().then((_) {
      onboarding = true;
      setState(() {});
    });

    await Future.delayed(transitionDuration * 0.8);

    homeAnimationController?.forward().then((_) {
      onboarded = true;
      setState(() {});

      clean();
    });
  }

  void clean() {
    onboardingAnimationController = null;
    homeAnimationController = null;

    setState(() {});
  }

  @override
  void dispose() {
    onboardingAnimationController?.dispose();
    homeAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (onboarded || onboardingAnimationController == null || homeAnimationController == null) {
      return widget.child;
    }

    final animation = onboardingAnimationController!.drive(CurveTween(curve: Curves.fastEaseInToSlowEaseOut));
    final homeAnimation = homeAnimationController!.drive(CurveTween(curve: Curves.fastEaseInToSlowEaseOut));

    return Material(
      color: ColorScheme.of(context).surface,
      child: Stack(
        children: [
          Visibility(
            visible: onboarding,
            child: AnimatedBuilder(
              animation: homeAnimation,
              child: FadeTransition(
                opacity: homeAnimation,
                child: widget.child,
              ),
              builder: (context, child) {
                return Container(
                  transform: Matrix4.identity()..translate(lerpDouble(56.0, 0.0, homeAnimation.value)!, 0.0),
                  child: child,
                );
              },
            ),
          ),
          Visibility(
            visible: !onboarded,
            child: AnimatedBuilder(
              animation: animation,
              child: FadeTransition(
                opacity: animation,
                child: SpNestedNavigation(
                  initialScreen: OnboardingView(
                    params: OnboardingRoute(),
                  ),
                ),
              ),
              builder: (context, child) {
                return Container(
                  transform: Matrix4.identity()..translate(lerpDouble(-56.0, 0.0, animation.value)!, 0.0),
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CutMiddleCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Draw a full circle
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    // Define the middle cut area (horizontal cut)
    double cutHeight = size.height * 0.3;
    Rect cutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: cutHeight,
    );

    // Cut out the middle part
    path.addRect(cutRect);
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CutMiddleCircleClipper oldClipper) => false;
}
