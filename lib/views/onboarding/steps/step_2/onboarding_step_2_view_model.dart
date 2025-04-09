import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_3/onboarding_step_3_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/onboarding/steps/step_4/onboarding_step_4_view.dart';
import 'onboarding_step_2_view.dart';

class OnboardingStep2ViewModel extends ChangeNotifier with DisposeAwareMixin {
  final OnboardingStep2Route params;

  OnboardingStep2ViewModel({
    required this.params,
  }) {
    startAnimations();
  }

  final Duration feelingClickDuration = const Duration(milliseconds: 500);
  final Duration toolbarFadeInDuration = const Duration(milliseconds: 750);

  final ValueNotifier<bool> feelingClickedNotifier = ValueNotifier(false);
  final ValueNotifier<String?> selectedFeelingNotifier = ValueNotifier(null);
  final ValueNotifier<bool> showToolbarNotifier = ValueNotifier(false);
  final ScrollController toolbarScrollController = ScrollController();

  void skip(BuildContext context) async {
    await OnboardingStep4Route().push(context);

    resetAnimations();
    startAnimations();
  }

  void next(BuildContext context) async {
    await OnboardingStep3Route().push(context);
    resetAnimations();
    startAnimations();
  }

  Future<void> startAnimations() async {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 250));

    await showFeelingClickAnimation();
    await selectedFeeling();
    await showToolbar();

    enableAutoscrollToolbar();
  }

  void resetAnimations() {
    feelingClickedNotifier.value = false;
    selectedFeelingNotifier.value = null;
    showToolbarNotifier.value = false;
  }

  Future<void> showFeelingClickAnimation() async {
    if (disposed) return;

    feelingClickedNotifier.value = true;
    await Future.delayed(feelingClickDuration);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> selectedFeeling() async {
    if (disposed) return;
    selectedFeelingNotifier.value = "positive_feelings";
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> showToolbar() async {
    if (disposed) return;
    showToolbarNotifier.value = true;
    await Future.delayed(toolbarFadeInDuration);
  }

  void enableAutoscrollToolbar() {
    if (disposed) return;
    if (!toolbarScrollController.hasClients) return;
    if (toolbarScrollController.offset != 0) toolbarScrollController.jumpTo(0.0);

    toolbarScrollController.animateTo(
      toolbarScrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 40),
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    feelingClickedNotifier.dispose();
    selectedFeelingNotifier.dispose();
    showToolbarNotifier.dispose();
    toolbarScrollController.dispose();
    super.dispose();
  }
}
