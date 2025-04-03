import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/views/languages/languages_view.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'onboarding_view_model.dart';

part 'onboarding_content.dart';

part 'local_widgets/next_button.dart';
part 'local_widgets/nickname_field.dart';

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
