import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_default_story_preferences_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class DefaultStoryPreferencesTile extends StatelessWidget {
  const DefaultStoryPreferencesTile({
    super.key,
    required this.weekday,
  });

  final int weekday;

  @override
  Widget build(BuildContext context) {
    final locked = !Provider.of<InAppPurchaseProvider>(context).isProUser;

    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.edit),
      title: Text(context.tr("list_tile.default_story_preferences.title")),
      trailing: locked ? const Icon(SpIcons.lock) : null,
      onTap: () async {
        // The sheet has no save button for pro users; it reports its live draft and
        // we commit it once here, after the sheet closes.
        DefaultStoryPreferencesObject? draft;
        await SpDefaultStoryPreferencesSheet(onChanged: (result) => draft = result).show(context: context);

        if (!context.mounted || draft == null) return;

        // Non-pro users are gated by the locked save button inside the sheet (paywall),
        // so their draft is never persisted here.
        if (context.read<InAppPurchaseProvider>().isProUser) {
          context.read<DevicePreferencesProvider>().setDefaultStoryPreferences(draft!);
        }
      },
    );
  }
}
