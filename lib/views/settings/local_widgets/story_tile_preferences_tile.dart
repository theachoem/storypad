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
      title: Text(context.tr("list_tile.story_tile_preferences.title")),
      trailing: locked ? const Icon(SpIcons.lock) : null,
      onTap: () async {
        // The sheet has no save button for pro users; it reports its live draft and
        // we commit it once here, after the sheet closes.
        StoryTilePreferencesObject? draft;
        await SpStoryTilePreferencesSheet(onChanged: (result) => draft = result).show(context: context);

        // delay to ensure the bottom sheet is fully closed before applying the new preferences,
        // which can trigger a rebuild of the story list and cause jank if done too early.
        await Future.delayed(const Duration(milliseconds: 500));

        if (!context.mounted || draft == null) return;

        // Non-pro users are gated by the locked save button inside the sheet (paywall),
        // so their draft is never persisted here.
        if (context.read<InAppPurchaseProvider>().isProUser) {
          context.read<DevicePreferencesProvider>().setStoryTilePreferences(draft!);
        }
      },
    );
  }
}
