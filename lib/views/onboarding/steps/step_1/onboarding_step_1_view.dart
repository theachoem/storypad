import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/onboarding/local_widgets/click_animation.dart';
import 'package:storypad/views/onboarding/local_widgets/fade_in_builder.dart';
import 'package:storypad/views/onboarding/local_widgets/home_screenshot.dart';
import 'package:storypad/views/onboarding/local_widgets/onboarding_template.dart';
import 'package:storypad/views/onboarding/local_widgets/story_details_screenshot.dart';
import 'package:storypad/views/onboarding/local_widgets/visible_when_notified.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'onboarding_step_1_view_model.dart';

part 'onboarding_step_1_content.dart';

class OnboardingStep1Route extends BaseRoute {
  OnboardingStep1Route();

  @override
  bool get preferredNestedRoute => true;

  @override
  Widget buildPage(BuildContext context) => OnboardingStep1View(params: this);
}

class OnboardingStep1View extends StatelessWidget {
  const OnboardingStep1View({
    super.key,
    required this.params,
  });

  final OnboardingStep1Route params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<OnboardingStep1ViewModel>(
      create: (context) => OnboardingStep1ViewModel(params: params),
      builder: (context, viewModel, child) {
        return _OnboardingStep1Content(viewModel);
      },
    );
  }
}
