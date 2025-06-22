import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/settings/local_widgets/time_format_tile.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/views/settings/local_widgets/color_seed_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_family_tile.dart';
import 'package:storypad/views/settings/local_widgets/font_weight_tile.dart';
import 'package:storypad/views/settings/local_widgets/theme_mode_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

import 'settings_view_model.dart';

part 'settings_content.dart';

class SettingsRoute extends BaseRoute {
  SettingsRoute({
    this.fromOnboarding = false,
  });

  final bool fromOnboarding;

  @override
  Map<String, String?>? get analyticsParameters {
    return {'from_onboarding': fromOnboarding.toString()};
  }

  @override
  Widget buildPage(BuildContext context) => SettingsView(params: this);
}

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.params,
  });

  final SettingsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SettingsViewModel>(
      create: (context) => SettingsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _SettingsContent(viewModel);
      },
    );
  }
}
