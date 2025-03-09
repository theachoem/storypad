import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_1/onboarding_step_1_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'onboarding_view.dart';

class OnboardingViewModel extends BaseViewModel {
  final OnboardingRoute params;

  OnboardingViewModel({
    required this.params,
  });

  final TextEditingController controller = TextEditingController();

  void next(BuildContext context) {
    if (Form.of(context).validate()) {
      OnboardingStep1Route().push(context);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
