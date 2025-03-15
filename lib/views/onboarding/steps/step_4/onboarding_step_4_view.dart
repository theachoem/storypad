import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/onboarding/local_widgets/onboarding_template.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'onboarding_step_4_view_model.dart';

part 'onboarding_step_4_content.dart';

class OnboardingStep4Route extends BaseRoute {
  OnboardingStep4Route();

  @override
  Widget buildPage(BuildContext context) => OnboardingStep4View(params: this);
}

class OnboardingStep4View extends StatelessWidget {
  const OnboardingStep4View({
    super.key,
    required this.params,
  });

  final OnboardingStep4Route params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<OnboardingStep4ViewModel>(
      create: (context) => OnboardingStep4ViewModel(params: params),
      builder: (context, viewModel, child) {
        return _OnboardingStep4Content(viewModel);
      },
    );
  }
}
