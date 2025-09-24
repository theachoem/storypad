import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/providers/backup_provider.dart';

import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpAssetInfoSheet extends BaseBottomSheet {
  final AssetDbModel asset;

  SpAssetInfoSheet({
    required this.asset,
  });

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(SpIcons.calendar),
          title: Text(tr("list_tile.updated_at.title")),
          subtitle: Text(context
              .read<DevicePreferencesProvider>()
              .preferences
              .timeFormat
              .formatDateTime(asset.updatedAt, context.locale)),
        ),
        ListTile(
          leading: const Icon(SpIcons.info),
          title: Text(tr("list_tile.created_at.title")),
          subtitle: Text(context
              .read<DevicePreferencesProvider>()
              .preferences
              .timeFormat
              .formatDateTime(asset.createdAt, context.locale)),
        ),
        if (context.read<BackupProvider>().currentUser != null)
          ListTile(
            leading: Icon(SpIcons.googleDrive),
            title: Text(
              tr('general.uploaded_to_args', namedArgs: {
                'URL':
                    asset.getGoogleDriveForEmails()?.contains(context.read<BackupProvider>().currentUser!.email) == true
                        ? context.read<BackupProvider>().currentUser!.email
                        : tr('general.na'),
              }),
            ),
            subtitle: Text(
                asset.getGoogleDriveUrlForEmail(context.read<BackupProvider>().currentUser!.email) ?? tr('general.na')),
          ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
