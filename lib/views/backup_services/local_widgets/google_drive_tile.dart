import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backup_services/show/show_backup_service_view.dart';
import 'package:storypad/widgets/sp_icons.dart';

class GoogleDriveTile extends StatelessWidget {
  const GoogleDriveTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);
    final service = provider.repository.googleDriveService;

    Widget leading = Icon(SpIcons.googleDrive);
    Widget? trailing;
    Widget title = Text.rich(
      TextSpan(
        text: 'Google Drive ',
        style: TextTheme.of(context).bodyLarge,
        children: [
          if (provider.currentUser?.photoUrl != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  provider.currentUser!.photoUrl!,
                ),
                radius: 8.0,
              ),
            ),
        ],
      ),
    );

    Widget subtitle = const Text("...");
    VoidCallback? onPressed;

    if (!provider.isSignedIn) {
      trailing = Icon(SpIcons.cloudOff);
      subtitle = Text(tr('list_tile.backup.unsignin_subtitle'));
      onPressed = () => provider.signIn(context, BackupServiceType.google_drive);
    } else {
      switch (provider.connectionStatus) {
        case BackupConnectionStatus.unknownError:
          trailing = Icon(SpIcons.cloudOff);
          subtitle = Text(tr('list_tile.backup.unknown_error'));
          onPressed = () => provider.recheckAndSync();
          break;
        case BackupConnectionStatus.noInternet:
          trailing = Icon(SpIcons.cloudOff);
          subtitle = Text(tr('list_tile.backup.no_internet_subtitle'));
          onPressed = () => provider.recheckAndSync();
          break;
        case BackupConnectionStatus.needGoogleDrivePermission:
          trailing = Icon(SpIcons.cloudOff);
          subtitle = Text(tr('list_tile.backup.no_permission_subtitle'));
          onPressed = () => provider.requestScope(context, BackupServiceType.google_drive);
          break;
        case BackupConnectionStatus.readyToSync:
          trailing = Icon(
            SpIcons.cloudUpload,
            color: ColorScheme.of(context).primary,
          );
          subtitle = Text(
            tr('list_tile.backup.some_data_has_not_sync_subtitle'),
          );
          onPressed = () => provider.recheckAndSync();
          break;
        case null:
          trailing = const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator.adaptive(),
          );
          subtitle = Text(tr('list_tile.backup.setting_up_connection'));
          break;
      }
    }

    if (provider.allYearSynced) {
      subtitle = Text(
        DateFormatHelper.yMEd_jmNullable(
              provider.lastSyncedAt,
              context.locale,
            ) ??
            '...',
      );
      onPressed = () => ShowBackupServiceRoute(service: service).push(context);
      trailing = Icon(
        SpIcons.cloudDone,
        color: ColorScheme.of(context).bootstrap.success.color,
      );
    }

    if (provider.syncing) {
      trailing = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator.adaptive(),
      );
      subtitle = Text(tr("general.syncing"));
      onPressed = () => ShowBackupServiceRoute(service: service).push(context);

      if (provider.step1Message != null) subtitle = Text("${tr("general.syncing")} 1/4");
      if (provider.step2Message != null) subtitle = Text("${tr("general.syncing")} 2/4");
      if (provider.step3Message != null) subtitle = Text("${tr("general.syncing")} 3/4");
      if (provider.step4Message != null) subtitle = Text("${tr("general.syncing")} 4/4");
    }

    return ListTile(
      onTap: onPressed,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}
