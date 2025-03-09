import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/onboarding_view.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

class OnboardingWrappper extends StatefulWidget {
  const OnboardingWrappper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<OnboardingWrappper> createState() => _OnboardingWrappperState();
}

class _OnboardingWrappperState extends State<OnboardingWrappper> {
  bool onboarded = false;

  @override
  Widget build(BuildContext context) {
    if (onboarded) {
      return widget.child;
    } else {
      return SpNestedNavigation(
        initialScreen: OnboardingView(
          params: OnboardingRoute(),
        ),
      );
    }
  }
}
