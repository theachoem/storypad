import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/core/services/backups/icloud_cloud_service.dart';
import 'package:storypad/widgets/bottom_sheets/sp_demo_images_sheet.dart';

/// Demo images + a single "Open Settings" button that hands off to Settings.
/// `ICloudCloudService.openAppSettings` can only open the app's own Settings
/// page (`UIApplication.openSettingsURLString` — the only public,
/// App-Store-safe deep link Apple provides), which has no iCloud row on it:
/// that row requires `NSUbiquitousContainers`, deliberately omitted so the
/// private container stays out of the Files app. The real toggle lives
/// under Settings → iCloud → See All → the app instead.
class SpICloudSettingsSheet {
  const SpICloudSettingsSheet._();

  static Future<void> show(
    BuildContext context, {
    required ICloudCloudService service,
  }) {
    return SpDemoImagesSheet(
      demoImages: SpDemoImagesSheet.icloudSettingsDemoImages,
      bottom: _ICloudSettingsButton(service: service),
    ).show(context: context);
  }
}

class _ICloudSettingsButton extends StatelessWidget {
  const _ICloudSettingsButton({required this.service});

  final ICloudCloudService service;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          // Textual equivalent of the demo images above, for screen readers
          // (which can't read the navigation path out of a screenshot) —
          // English-only for now; other locales follow separately.
          Text(
            tr('dialog.icloud_settings.navigation_steps', namedArgs: {'SP_APP_NAME': kAppName}),
            textAlign: TextAlign.center,
            style: TextTheme.of(context).bodySmall,
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                // Only dismiss once Settings actually opened — a discarded
                // failure here would leave the user with no route to enable
                // iCloud and no indication anything went wrong.
                final opened = await service.openAppSettings();
                if (opened && context.mounted) Navigator.maybePop(context);
              },
              icon: const Icon(SpIcons.setting),
              label: Text(tr('button.open_settings')),
            ),
          ),
        ],
      ),
    );
  }
}
