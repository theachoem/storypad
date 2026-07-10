import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/notifications/local_notification_service.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/views/app_locks/app_locks_view.dart';
import 'package:storypad/views/reminders/reminders_view.dart';
import 'package:storypad/views/settings/appearance/appearance_view.dart';
import 'package:storypad/views/settings/data_backup/data_backup_view.dart';
import 'package:storypad/views/settings/local_widgets/first_day_of_week_tile.dart';
import 'package:storypad/views/settings/local_widgets/language_tile.dart';
import 'package:storypad/views/settings/local_widgets/my_templates_tile.dart';
import 'package:storypad/views/settings/local_widgets/time_format_tile.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/views/settings/local_widgets/default_story_preferences_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

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
  String? get routeName => 'settings';

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
    return ChangeNotifierProvider<SettingsViewModel>(
      create: (context) => SettingsViewModel(params: params),
      builder: (context, child) {
        return _SettingsContent(Provider.of(context));
      },
    );
  }
}
