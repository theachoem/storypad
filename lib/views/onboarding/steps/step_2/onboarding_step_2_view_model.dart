import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_3/onboarding_step_3_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'onboarding_step_2_view.dart';

class OnboardingStep2ViewModel extends BaseViewModel {
  final OnboardingStep2Route params;

  OnboardingStep2ViewModel({
    required this.params,
  });

  void next(BuildContext context) {
    OnboardingStep3Route().push(context);
  }
}
