import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/views/onboarding/steps/onboarding_hello_view.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'onboarding_view.dart';

class OnboardingViewModel extends BaseViewModel {
  final OnboardingRoute params;

  OnboardingViewModel({
    required this.params,
  });

  final TextEditingController controller = TextEditingController();

  void next(BuildContext context) {
    if (Form.of(context).validate()) {
      String nickname = controller.text.trim();
      PreferenceDbModel.db.nickname.set(nickname);
      OnboardingHelloRoute(nickname: nickname).push(context);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
