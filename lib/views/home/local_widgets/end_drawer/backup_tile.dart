part of 'home_end_drawer.dart';

class _BackupTile extends StatefulWidget {
  const _BackupTile();

  @override
  State<_BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends State<_BackupTile> {
  bool focusing = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);

    Widget? button;
    Widget? leading;
    Widget? subtitle;

    subtitle = Text(tr('list_tile.backup.unsignin_subtitle'));

    if (provider.currentUser?.photoUrl != null) {
      leading = Transform.scale(
        scale: 1.5,
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(provider.currentUser!.photoUrl!),
          radius: 12.0,
        ),
      );
    } else {
      leading = const Icon(SpIcons.cloudUpload);
    }

    switch (provider.backupStatus) {
      case null:
      case BackupTileStatus.authenticating:
        leading = const SizedBox.square(
          dimension: 24.0,
          child: CircularProgressIndicator.adaptive(),
        );
        subtitle = const Text("Authenticating...");
        break;
      case BackupTileStatus.noInternetToCheck:
        subtitle = const Text("No internet to check");
        button = OutlinedButton.icon(
          label: Text(tr("button.retry")),
          onPressed: () => provider.retry(),
        );
        break;
      case BackupTileStatus.noSignIn:
        subtitle = Text(tr('list_tile.backup.unsignin_subtitle'));
        button = OutlinedButton.icon(
          label: Text(tr("button.sign_in")),
          onPressed: () => provider.signIn(),
        );
        break;
      case BackupTileStatus.errorShouldRetry:
        subtitle = const Text("Error accur");
        button = OutlinedButton.icon(
          label: Text(tr("button.retry")),
          onPressed: () => provider.retry(),
        );
        break;
      case BackupTileStatus.needRequestAccessScopes:
        subtitle = const Text("Need google drive permision");
        button = OutlinedButton.icon(
          label: const Text("Request access"),
          onPressed: () => provider.requestAccessScopesAndSync(),
        );
        break;
      case BackupTileStatus.uploadingAssets:
        leading = const SizedBox.square(
          dimension: 24.0,
          child: CircularProgressIndicator.adaptive(),
        );
        subtitle = const Text("Uploading media...");
        break;
      case BackupTileStatus.checkingLatestBackupWithCloud:
        leading = const SizedBox.square(
          dimension: 24.0,
          child: CircularProgressIndicator.adaptive(),
        );
        subtitle = const Text("Checking latest backup...");
        break;
      case BackupTileStatus.restoringLatestBackupFromCloud:
        leading = const SizedBox.square(
          dimension: 24.0,
          child: CircularProgressIndicator.adaptive(),
        );
        subtitle = const Text("Restoring latest backup...");
        break;
      case BackupTileStatus.uploadingBackupFromThisDevice:
        leading = const SizedBox.square(
          dimension: 24.0,
          child: CircularProgressIndicator.adaptive(),
        );
        subtitle = const Text("Uploading backup from this device");
        break;
      case BackupTileStatus.canSync:
        subtitle = Text(tr("list_tile.backup.some_data_has_not_sync_subtitle"));
        button = OutlinedButton.icon(
          label: const Text("sync"),
          onPressed: () => provider.syncFromCloudIfNeeded(),
        );
        break;
      case BackupTileStatus.synced:
        leading = Icon(SpIcons.cloudDone, color: ColorScheme.of(context).bootstrap.success.color);
        subtitle = Text(
          DateFormatHelper.yMEd_jmNullable(provider.lastSyncedAt, context.locale) ??
              provider.currentUser?.email ??
              '...',
        );
        break;
    }

    Widget tile = ListTile(
      onTap: () => BackupsRoute().push(context),
      leading: leading,
      subtitle: subtitle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: provider.backupStatus != BackupTileStatus.synced
          ? Text(tr("list_tile.backup.title"))
          : RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                text: "${tr("list_tile.backup.title")} ",
                style: TextTheme.of(context).bodyLarge,
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      SpIcons.cloudDone,
                      color: ColorScheme.of(context).bootstrap.success.color,
                      size: 16.0,
                    ),
                  ),
                ],
              ),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0.0,
      children: [
        tile,
        if (button != null)
          Container(
            margin: const EdgeInsets.only(left: 52.0),
            transform: Matrix4.identity()..translate(0.0, -8.0),
            child: button,
          ),
      ],
    );
  }
}
