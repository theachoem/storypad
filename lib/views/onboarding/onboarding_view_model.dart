import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/onboarding_hello_view.dart';
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
      OnboardingHelloRoute().push(context);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
