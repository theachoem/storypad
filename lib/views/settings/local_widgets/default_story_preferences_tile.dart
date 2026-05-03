import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_default_story_preferences_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class DefaultStoryPreferencesTile extends StatelessWidget {
  const DefaultStoryPreferencesTile({super.key, required this.weekday});

  final int weekday;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.edit),
      title: Text(tr("list_tile.default_story_preferences.title")),
      onTap: () async {
        final result = await const SpDefaultStoryPreferencesSheet().show(context: context);
        if (context.mounted && result is DefaultStoryPreferencesObject) {
          context.read<DevicePreferencesProvider>().setDefaultStoryPreferences(result);
        }
      },
    );
  }
}
