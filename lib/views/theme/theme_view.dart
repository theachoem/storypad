import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/views/theme/local_widgets/color_seed_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_family_tile.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/views/theme/local_widgets/theme_mode_tile.dart';

import 'theme_view_model.dart';

part 'theme_content.dart';

class ThemeRoute extends BaseRoute {
  ThemeRoute({
    this.fromOnboarding = false,
  });

  final bool fromOnboarding;

  @override
  Map<String, String?>? get analyticsParameters {
    return {'from_onboarding': fromOnboarding.toString()};
  }

  @override
  Widget buildPage(BuildContext context) => ThemeView(params: this);
}

class ThemeView extends StatelessWidget {
  const ThemeView({
    super.key,
    required this.params,
  });

  final ThemeRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ThemeViewModel>(
      create: (context) => ThemeViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ThemeContent(viewModel);
      },
    );
  }
}
