import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_2/onboarding_step_2_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'onboarding_step_1_view.dart';

class OnboardingStep1ViewModel extends BaseViewModel {
  final OnboardingStep1Route params;

  OnboardingStep1ViewModel({
    required this.params,
  });

  void next(BuildContext context) {
    OnboardingStep2Route().push(context);
  }
}
