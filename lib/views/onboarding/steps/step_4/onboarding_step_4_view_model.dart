import 'package:flutter/material.dart';
import 'package:storypad/core/storages/onboarded_storage.dart';
import 'package:storypad/widgets/sp_onboarding_wrapper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'onboarding_step_4_view.dart';

class OnboardingStep4ViewModel extends ChangeNotifier with DisposeAwareMixin {
  final OnboardingStep4Route params;

  OnboardingStep4ViewModel({
    required this.params,
  });

  void getStarted(BuildContext context) {
    OnboardedStorage().write(true);
    SpOnboardingWrappper.close(context);
  }
}
