import 'package:animations/animations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/onboarding/local_widgets/onboarding_template.dart';
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
  SharedAxisTransitionType get transitionType => SharedAxisTransitionType.vertical;

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
