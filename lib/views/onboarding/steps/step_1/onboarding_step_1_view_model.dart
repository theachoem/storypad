import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_2/onboarding_step_2_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
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

  void startAnimations() async {
    await Future.delayed(Duration(seconds: 2));
    await showClickAnimation();
    await showStoryDetailsPageAnimation();
  }

  Future<void> next(BuildContext context) async {
    await showClickAnimation();
    await showStoryDetailsPageAnimation();
    await hideHomePageAnimation();

    if (!context.mounted) return;

    await OnboardingStep2Route().push(context);
    resetAnimations();

    await Future.delayed(Duration(milliseconds: 350));
    startAnimations();
  }

  Future<void> showClickAnimation() async {
    if (disposed) return;
    if (showStoryClickedNotifier.value == false) {
      showStoryClickedNotifier.value = true;

      await Future.delayed(clickDuration);
      await Future.delayed(Duration(milliseconds: 350));
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
      await Future.delayed(Duration(milliseconds: 500));
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
