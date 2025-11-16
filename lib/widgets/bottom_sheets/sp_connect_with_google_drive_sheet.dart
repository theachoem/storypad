import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_connect_google_drive_button.dart';
import 'package:storypad/widgets/sp_icons.dart';

// currently message only for IAP, let's add more later if needed.
class SpConnectWithGoogleDriveSheet extends BaseBottomSheet {
  SpConnectWithGoogleDriveSheet();

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            SpIcons.cloudDone,
            size: 24,
            color: ColorScheme.of(context).bootstrap.info.color,
          ),
          const SizedBox(height: 16.0),
          Text(
            tr("dialog.iap_backup_required.title"),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
          ),
          const SizedBox(height: 8.0),
          Text(
            tr('dialog.iap_backup_required.message'),
            style: TextTheme.of(context).bodyLarge,
            maxLines: null,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          SpConnectGoogleDriveButton(
            onPressed: () async {
              await context.read<BackupProvider>().signIn(context, BackupServiceType.google_drive);
              if (context.mounted) Navigator.maybePop(context);
            },
          ),
          buildBottomPadding(bottomPadding),
        ],
      ),
    );
  }
}
