import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/local_widgets/end_drawer_screenshot.dart';
import 'package:storypad/views/onboarding/steps/step_4/onboarding_step_4_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'onboarding_step_3_view.dart';

class OnboardingStep3ViewModel extends ChangeNotifier with DisposeAwareMixin {
  final OnboardingStep3Route params;

  OnboardingStep3ViewModel({
    required this.params,
  }) {
    startAnimations();
  }

  final endDrawerFadeInDuration = Duration(milliseconds: 1000);
  final clickDuration = Duration(milliseconds: 500);

  final endDrawerOpenedNotifier = ValueNotifier(false);
  final endDrawerStateNotifier = ValueNotifier(EndDrawerScreenshotState.noSignedIn);
  final endDrawerScrollController = ScrollController();

  final showSignInClickedNotifier = ValueNotifier(false);
  final showSyncClickedNotifier = ValueNotifier(false);

  void next(BuildContext context) async {
    await OnboardingStep4Route().push(context);

    resetAnimations();
    startAnimations();
  }

  Future<void> startAnimations() async {
    await Future.delayed(Duration(milliseconds: 500));

    await openEndDrawer();
    await scrollToBackupSection();

    await showSignInClickAnimation();
    await changeStateTo(EndDrawerScreenshotState.signedIn);

    await showSyncClickAnimation();
    await changeStateTo(EndDrawerScreenshotState.syning);

    await changeStateTo(EndDrawerScreenshotState.synced);
  }

  void resetAnimations() {
    endDrawerOpenedNotifier.value = false;
    endDrawerStateNotifier.value = EndDrawerScreenshotState.noSignedIn;
    endDrawerStateNotifier.value = EndDrawerScreenshotState.noSignedIn;
    endDrawerScrollController.jumpTo(0.0);
    showSignInClickedNotifier.value = false;
    showSyncClickedNotifier.value = false;
  }

  Future<void> openEndDrawer() async {
    if (disposed) return;

    endDrawerOpenedNotifier.value = true;
    await Future.delayed(endDrawerFadeInDuration);
  }

  Future<void> scrollToBackupSection() async {
    if (disposed) return;
    await endDrawerScrollController.animateTo(100, duration: Durations.long4, curve: Curves.fastEaseInToSlowEaseOut);
  }

  Future<void> showSignInClickAnimation() async {
    if (disposed) return;

    showSignInClickedNotifier.value = true;
    await Future.delayed(clickDuration + Duration(milliseconds: 500));
  }

  Future<void> showSyncClickAnimation() async {
    if (disposed) return;

    showSyncClickedNotifier.value = true;
    await Future.delayed(clickDuration + Duration(milliseconds: 500));
  }

  Future<void> changeStateTo(EndDrawerScreenshotState state) async {
    if (disposed) return;

    endDrawerStateNotifier.value = state;
    await Future.delayed(Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    endDrawerOpenedNotifier.dispose();
    endDrawerStateNotifier.dispose();
    endDrawerScrollController.dispose();
    showSignInClickedNotifier.dispose();
    showSyncClickedNotifier.dispose();
    super.dispose();
  }
}
