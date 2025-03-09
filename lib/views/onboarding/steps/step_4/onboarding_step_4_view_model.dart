import 'package:flutter/material.dart';
import 'package:storypad/core/storages/onboarded_storage.dart';
import 'package:storypad/widgets/sp_onboarding_wrapper.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'onboarding_step_4_view.dart';

class OnboardingStep4ViewModel extends BaseViewModel {
  final OnboardingStep4Route params;

  OnboardingStep4ViewModel({
    required this.params,
  });

  void getStarted(BuildContext context) {
    OnboardedStorage().write(true);
    SpOnboardingWrappper.close(context);
  }
}
