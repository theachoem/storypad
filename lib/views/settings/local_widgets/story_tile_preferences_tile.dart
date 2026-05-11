import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_story_tile_preferences_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class StoryTilePreferencesTile extends StatelessWidget {
  const StoryTilePreferencesTile({super.key, required this.weekday});

  final int weekday;

  @override
  Widget build(BuildContext context) {
    final locked = !Provider.of<InAppPurchaseProvider>(context).isProUser;

    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.tune),
      title: Text(tr("list_tile.story_tile_preferences.title")),
      trailing: locked ? const Icon(SpIcons.lock) : null,
      onTap: () async {
        final result = await const SpStoryTilePreferencesSheet().show(context: context);

        // delay to ensure the bottom sheet is fully closed before applying the new preferences,
        // which can trigger a rebuild of the story list and cause jank if done too early.
        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted && result is StoryTilePreferencesObject) {
          context.read<DevicePreferencesProvider>().setStoryTilePreferences(result);
        }
      },
    );
  }
}
