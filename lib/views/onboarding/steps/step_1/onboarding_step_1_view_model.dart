import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/services/avoid_dublicated_call_service.dart';
import 'package:storypad/views/onboarding/steps/step_2/onboarding_step_2_view.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'onboarding_step_1_view.dart';

class OnboardingStep1ViewModel extends BaseViewModel {
  final OnboardingStep1Route params;

  OnboardingStep1ViewModel({
    required this.params,
  }) {
    startAnimations();
  }

  final Duration clickDuration = Duration(milliseconds: 500);
  final Duration storyDetailsAnimationDuration = Duration(milliseconds: 1000);

  final ValueNotifier<bool> showHomePageNotifier = ValueNotifier(true);
  final ValueNotifier<bool> showStoryClickedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> showStoryDetailsPageNotifier = ValueNotifier(false);

  bool _navigating = false;

  Future<void> next(BuildContext context) async {
    if (_navigating) return;
    _navigating = true;

    await showClickAnimation();
    await showStoryDetailsPageAnimation();
    await hideHomePageAnimation();

    _navigating = false;
    if (!context.mounted) return;
    await OnboardingStep2Route().push(context);

    resetAnimations();
    startAnimations();
  }

  void startAnimations() async {
    if (disposed) return;

    await Future.delayed(Duration(seconds: 2));
    await showClickAnimation();
    await showStoryDetailsPageAnimation();
  }

  final AvoidDublicatedCallService _clickAnimation = AvoidDublicatedCallService();
  Future<void> showClickAnimation() async {
    return _clickAnimation.run(() async {
      if (disposed) return;
      if (showStoryClickedNotifier.value == false) {
        showStoryClickedNotifier.value = true;

        await Future.delayed(clickDuration);
        await Future.delayed(Duration(milliseconds: 350));
      }
    });
  }

  final AvoidDublicatedCallService _storyDetailsPageAnimation = AvoidDublicatedCallService();
  Future<void> showStoryDetailsPageAnimation() async {
    return _storyDetailsPageAnimation.run(() async {
      if (disposed) return;
      if (showStoryDetailsPageNotifier.value == false) {
        showStoryDetailsPageNotifier.value = true;
        await Future.delayed(storyDetailsAnimationDuration);
      }
    });
  }

  final AvoidDublicatedCallService _homePageAnimation = AvoidDublicatedCallService();
  Future<void> hideHomePageAnimation() async {
    return _homePageAnimation.run(() async {
      if (disposed) return;
      if (showHomePageNotifier.value == true) {
        showHomePageNotifier.value = false;
        await Future.delayed(Duration(milliseconds: 500));
      }
    });
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
