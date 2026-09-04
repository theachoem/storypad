import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/core/services/backups/icloud_cloud_service.dart';
import 'package:storypad/widgets/bottom_sheets/sp_demo_images_sheet.dart';

/// Demo images + a single "Open Settings" button that hands off to Settings.
/// `ICloudCloudService.openAppSettings` can only open the app's own Settings
/// page (`UIApplication.openSettingsURLString` — the only public,
/// App-Store-safe deep link Apple provides), which has no iCloud row on it:
/// that row requires `NSUbiquitousContainers`, deliberately omitted so the
/// private container stays out of the Files app. The real toggle lives
/// under Settings → [Apple ID] → iCloud → Apps Using iCloud instead.
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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            service.openAppSettings();
            Navigator.maybePop(context);
          },
          icon: const Icon(SpIcons.setting),
          label: Text(tr('button.open_settings')),
        ),
      ),
    );
  }
}
