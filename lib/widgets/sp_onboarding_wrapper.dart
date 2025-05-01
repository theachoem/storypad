import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:storypad/initializers/onboarding_initializer.dart';
import 'package:storypad/views/onboarding/onboarding_view.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class SpOnboardingWrappper extends StatefulWidget {
  const SpOnboardingWrappper({
    super.key,
    required this.child,
    required this.onOnboarded,
  });

  final Widget child;
  final Future<void> Function() onOnboarded;

  static void close(BuildContext context) {
    context.findAncestorStateOfType<_SpOnboardingWrappperState>()?.close();
  }

  static void open(BuildContext context) {
    context.findAncestorStateOfType<_SpOnboardingWrappperState>()?.open();
  }

  @override
  State<SpOnboardingWrappper> createState() => _SpOnboardingWrappperState();
}

class _SpOnboardingWrappperState extends State<SpOnboardingWrappper> with TickerProviderStateMixin {
  AnimationController? onboardingAnimationController;
  AnimationController? homeAnimationController;

  final transitionDuration = const Duration(milliseconds: 750);

  bool onboarding = false;
  bool onboarded = OnboardingInitializer.onboarded ?? !OnboardingInitializer.isNewUser;

  @override
  void initState() {
    super.initState();

    if (!onboarded) {
      onboardingAnimationController = AnimationController(vsync: this, duration: transitionDuration, value: 1.0);
      homeAnimationController = AnimationController(vsync: this, duration: transitionDuration, value: 0.0);
    }
  }

  Future<void> open() async {
    onboarded = false;
    setState(() {});

    onboardingAnimationController ??= AnimationController(vsync: this, duration: transitionDuration, value: 1.0);
    homeAnimationController ??= AnimationController(vsync: this, duration: transitionDuration, value: 0.0);
  }

  Future<void> close() async {
    await widget.onOnboarded();

    onboardingAnimationController?.reverse().then((_) {
      onboarding = true;
      setState(() {});
    });

    await Future.delayed(transitionDuration * 0.8);
    await homeAnimationController?.forward().then((_) {
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

    return PopScope(
      canPop: false,
      child: Material(
        color: ColorScheme.of(context).surface,
        child: Stack(
          children: [
            buildHomeAnimation(child: widget.child),
            buildOnboardingAnimation(
              child: SpNestedNavigation(
                initialScreen: OnboardingView(params: OnboardingRoute()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHomeAnimation({
    required Widget child,
  }) {
    final homeAnimation = homeAnimationController!.drive(CurveTween(curve: Curves.fastEaseInToSlowEaseOut));
    return Visibility(
      visible: onboarding,
      child: AnimatedBuilder(
        animation: homeAnimation,
        child: FadeTransition(
          opacity: homeAnimation,
          child: child,
        ),
        builder: (context, child) {
          return Container(
            transform: Matrix4.identity()..translate(0.0, lerpDouble(56.0, 0.0, homeAnimation.value)!),
            child: child,
          );
        },
      ),
    );
  }

  Widget buildOnboardingAnimation({
    required Widget child,
  }) {
    final animation = onboardingAnimationController!.drive(CurveTween(curve: Curves.fastEaseInToSlowEaseOut));
    return Visibility(
      visible: !onboarded,
      child: AnimatedBuilder(
        animation: animation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
        builder: (context, child) {
          return Container(
            transform: Matrix4.identity()..translate(0.0, lerpDouble(-56.0, 0.0, animation.value)!),
            child: child,
          );
        },
      ),
    );
  }
}
