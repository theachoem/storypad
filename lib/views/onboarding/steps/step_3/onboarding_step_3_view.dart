import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/onboarding/local_widgets/click_animation.dart';
import 'package:storypad/views/onboarding/local_widgets/end_drawer_screenshot.dart';
import 'package:storypad/views/onboarding/local_widgets/fade_in_builder.dart';
import 'package:storypad/views/onboarding/local_widgets/home_screenshot.dart';
import 'package:storypad/views/onboarding/local_widgets/onboarding_template.dart';
import 'package:storypad/views/onboarding/local_widgets/visible_when_notified.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'onboarding_step_3_view_model.dart';

part 'onboarding_step_3_content.dart';

class OnboardingStep3Route extends BaseRoute {
  OnboardingStep3Route();

  @override
  Widget buildPage(BuildContext context) => OnboardingStep3View(params: this);
}

class OnboardingStep3View extends StatelessWidget {
  const OnboardingStep3View({
    super.key,
    required this.params,
  });

  final OnboardingStep3Route params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<OnboardingStep3ViewModel>(
      create: (context) => OnboardingStep3ViewModel(params: params),
      builder: (context, viewModel, child) {
        return _OnboardingStep3Content(viewModel);
      },
    );
  }
}
