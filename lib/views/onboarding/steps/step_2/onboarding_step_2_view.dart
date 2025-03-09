import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/views/onboarding/local_widgets/click_animation.dart';
import 'package:storypad/views/onboarding/local_widgets/fade_in_builder.dart';
import 'package:storypad/views/onboarding/local_widgets/onboarding_template.dart';
import 'package:storypad/views/onboarding/local_widgets/story_details_screenshot.dart';
import 'package:storypad/views/onboarding/local_widgets/visible_when_notified.dart';
import 'package:storypad/widgets/feeling_picker/sp_feeling_button.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'onboarding_step_2_view_model.dart';

part 'onboarding_step_2_content.dart';

class OnboardingStep2Route extends BaseRoute {
  OnboardingStep2Route();

  @override
  bool get preferredNestedRoute => true;

  @override
  Widget buildPage(BuildContext context) => OnboardingStep2View(params: this);
}

class OnboardingStep2View extends StatelessWidget {
  const OnboardingStep2View({
    super.key,
    required this.params,
  });

  final OnboardingStep2Route params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<OnboardingStep2ViewModel>(
      create: (context) => OnboardingStep2ViewModel(params: params),
      builder: (context, viewModel, child) {
        return _OnboardingStep2Content(viewModel);
      },
    );
  }
}
