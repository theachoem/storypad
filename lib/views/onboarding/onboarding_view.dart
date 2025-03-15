import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/views/languages/languages_view.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'onboarding_view_model.dart';

part 'onboarding_content.dart';

class OnboardingRoute extends BaseRoute {
  OnboardingRoute();

  @override
  Widget buildPage(BuildContext context) => OnboardingView(params: this);
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({
    super.key,
    required this.params,
  });

  final OnboardingRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<OnboardingViewModel>(
      create: (context) => OnboardingViewModel(params: params),
      builder: (context, viewModel, child) {
        return _OnboardingContent(viewModel);
      },
    );
  }
}
