import 'package:flutter/material.dart';

class OnboardingWrappper extends StatelessWidget {
  const OnboardingWrappper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
