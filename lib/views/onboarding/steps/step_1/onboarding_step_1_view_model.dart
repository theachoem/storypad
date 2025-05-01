import 'dart:async';
import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_2/onboarding_step_2_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/onboarding/steps/step_4/onboarding_step_4_view.dart';
import 'onboarding_step_1_view.dart';

class OnboardingStep1ViewModel extends ChangeNotifier with DisposeAwareMixin {
  final OnboardingStep1Route params;

  OnboardingStep1ViewModel({
    required this.params,
  }) {
    startAnimations();
  }

  final Duration clickDuration = const Duration(milliseconds: 500);
  final Duration storyDetailsAnimationDuration = const Duration(milliseconds: 1000);

  final ValueNotifier<bool> showHomePageNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showStoryClickedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> showStoryDetailsPageNotifier = ValueNotifier(false);

  void skip(BuildContext context) async {
    await OnboardingStep4Route().push(context);

    resetAnimations();
    startAnimations();
  }

  Future<void> next(BuildContext context) async {
    if (!context.mounted) return;
    await OnboardingStep2Route().push(context);

    resetAnimations();
    startAnimations();
  }

  void startAnimations() async {
    if (disposed) return;

    await Future.delayed(const Duration(seconds: 1));
    await showClickAnimation();
    await showStoryDetailsPageAnimation();
  }

  Future<void> showClickAnimation() async {
    if (disposed) return;
    if (showStoryClickedNotifier.value == false) {
      showStoryClickedNotifier.value = true;

      await Future.delayed(clickDuration);
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> showStoryDetailsPageAnimation() async {
    if (disposed) return;
    if (showStoryDetailsPageNotifier.value == false) {
      showStoryDetailsPageNotifier.value = true;
      await Future.delayed(storyDetailsAnimationDuration);
    }
  }

  Future<void> hideHomePageAnimation() async {
    if (disposed) return;
    if (showHomePageNotifier.value == true) {
      showHomePageNotifier.value = false;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void resetAnimations() {
    if (disposed) return;

    showHomePageNotifier.value = true;
    showStoryClickedNotifier.value = false;
    showStoryDetailsPageNotifier.value = false;
  }

  @override
  void dispose() {
    showHomePageNotifier.dispose();
    showStoryClickedNotifier.dispose();
    showStoryDetailsPageNotifier.dispose();
    super.dispose();
  }
}
