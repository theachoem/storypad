import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_4/onboarding_step_4_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'onboarding_step_3_view.dart';

class OnboardingStep3ViewModel extends BaseViewModel {
  final OnboardingStep3Route params;

  OnboardingStep3ViewModel({
    required this.params,
  });

  void next(BuildContext context) {
    OnboardingStep4Route().push(context);
  }
}
