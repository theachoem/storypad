import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/core/initializers/onboarding_initializer.dart';
import 'package:storypad/views/onboarding/onboarding_view.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class SpOnboardingWrapper extends StatefulWidget {
  const SpOnboardingWrapper({
    super.key,
    required this.child,
    required this.onOnboarded,
  });

  final Widget child;
  final void Function() onOnboarded;

  static void close(BuildContext context) {
    context.findAncestorStateOfType<_SpOnboardingWrapperState>()?.close();
  }

  static void open(BuildContext context) {
    context.findAncestorStateOfType<_SpOnboardingWrapperState>()?.open();
  }

  @override
  State<SpOnboardingWrapper> createState() => _SpOnboardingWrapperState();
}

class _SpOnboardingWrapperState extends State<SpOnboardingWrapper> with TickerProviderStateMixin {
  AnimationController? onboardingAnimationController;
  AnimationController? homeAnimationController;

  final transitionDuration = const Duration(milliseconds: 750);

  bool onboarding = false;
  bool onboarded = OnboardingInitializer.onboarded ?? !OnboardingInitializer.isNewUser;
  GlobalKey<NavigatorState>? onboardingKey;

  @override
  void initState() {
    super.initState();

    if (!onboarded) {
      onboardingAnimationController = AnimationController(vsync: this, duration: transitionDuration, value: 1.0);
      homeAnimationController = AnimationController(vsync: this, duration: transitionDuration, value: 0.0);
      onboardingKey = GlobalKey();
    }
  }

  Future<void> open() async {
    onboarded = false;
    onboardingKey ??= GlobalKey();

    onboardingAnimationController ??= AnimationController(vsync: this, duration: transitionDuration, value: 1.0);
    homeAnimationController ??= AnimationController(vsync: this, duration: transitionDuration, value: 0.0);

    setState(() {});
  }

  Future<void> close() async {
    widget.onOnboarded();

    await onboardingAnimationController?.reverse().then((_) {
      onboarding = true;
      setState(() {});
    });

    await homeAnimationController?.forward();

    Future.microtask(() {
      onboarded = true;
      clean();
    });
  }

  void clean() {
    onboardingAnimationController = null;
    homeAnimationController = null;
    onboardingKey = null;
    setState(() {});
  }

  @override
  void dispose() {
    onboardingAnimationController?.dispose();
    homeAnimationController?.dispose();
    onboardingKey = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (onboarded || onboardingAnimationController == null || homeAnimationController == null) {
      return widget.child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => onboardingKey?.currentState?.maybePop(result),
      child: Material(
        color: ColorScheme.of(context).surface,
        child: Stack(
          children: [
            buildHomeAnimation(child: widget.child),
            buildOnboardingAnimation(
              child: SpNestedNavigation(
                navigatorKey: onboardingKey,
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
            transform: Matrix4.identity()..spTranslate(0.0, lerpDouble(56.0, 0.0, homeAnimation.value)!),
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
            transform: Matrix4.identity()..spTranslate(0.0, lerpDouble(-56.0, 0.0, animation.value)!),
            child: child,
          );
        },
      ),
    );
  }
}
