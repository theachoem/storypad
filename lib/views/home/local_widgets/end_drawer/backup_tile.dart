part of 'home_end_drawer.dart';

class _BackupTile extends StatelessWidget {
  const _BackupTile();

  @override
  Widget build(BuildContext context) {
    BackupProvider provider = Provider.of<BackupProvider>(context);

    Widget leading;
    Widget title = const Text("...");
    Widget subtitle = const Text("...");
    Widget? action;

    if (!provider.isSignedIn) {
      leading = Icon(SpIcons.cloudOff);
      title = Text(tr("list_tile.backup.title"));
      subtitle = Text(tr('list_tile.backup.unsignin_subtitle'));
      action = FilledButton.icon(
        icon: Icon(SpIcons.googleDrive),
        label: Text(tr('button.sign_in')),
        onPressed: () => provider.signIn(context),
      );
    } else {
      switch (provider.connectionStatus) {
        case BackupConnectionStatus.unknownError:
          leading = Icon(SpIcons.cloudOff);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.unknown_error'));
          action = FilledButton.icon(
            icon: const Icon(SpIcons.refresh),
            label: Text(tr('button.retry')),
            onPressed: () => provider.recheckAndSync(),
          );
          break;
        case BackupConnectionStatus.noInternet:
          leading = Icon(SpIcons.cloudOff);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.no_internet_subtitle'));
          action = FilledButton.icon(
            icon: const Icon(SpIcons.refresh),
            label: Text(tr('button.refresh')),
            onPressed: () => provider.recheckAndSync(),
          );
          break;
        case BackupConnectionStatus.needGoogleDrivePermission:
          leading = Icon(SpIcons.cloudOff);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.no_permission_subtitle'));
          action = FilledButton.icon(
            icon: Icon(SpIcons.googleDrive),
            label: Text(tr('button.grant_permission')),
            onPressed: () => provider.requestScope(context),
          );
          break;
        case BackupConnectionStatus.readyToSync:
          leading = Icon(SpIcons.googleDrive);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.some_data_has_not_sync_subtitle'));
          action = FilledButton(
            child: Text(tr('button.sync')),
            onPressed: () => provider.recheckAndSync(),
          );
          break;
        case null:
          leading = const SizedBox.square(dimension: 24, child: CircularProgressIndicator.adaptive());
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.setting_up_connection'));
          action = null;
          break;
      }
    }

    if (provider.synced) {
      leading = Icon(SpIcons.googleDrive);
      subtitle = Text(DateFormatHelper.yMEd_jmNullable(provider.lastSyncedAt, context.locale) ?? '...');
      action = null;
      title = RichText(
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
      );
    }

    if (provider.syncing) {
      leading = const SizedBox.square(dimension: 24, child: CircularProgressIndicator.adaptive());
      subtitle = Text(tr("general.syncing"));
      action = null;

      if (provider.step1Message != null) subtitle = Text("${tr("general.syncing")} 1/4");
      if (provider.step2Message != null) subtitle = Text("${tr("general.syncing")} 2/4");
      if (provider.step3Message != null) subtitle = Text("${tr("general.syncing")} 3/4");
      if (provider.step4Message != null) subtitle = Text("${tr("general.syncing")} 4/4");

      title = RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          text: tr("list_tile.backup.title"),
          style: TextTheme.of(context).bodyLarge,
          children: [
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox.square(dimension: 12, child: CircularProgressIndicator.adaptive(strokeWidth: 2)),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.currentUser?.photoUrl != null) {
      leading = Transform.scale(
        scale: 1.5,
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(provider.currentUser!.photoUrl!),
          radius: 12.0,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: () => BackupsRoute().push(context),
          leading: leading,
          title: title,
          subtitle: subtitle,
        ),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(left: 52.0),
            child: action,
          ),
        const SizedBox(height: 4.0),
      ],
    );
  }
}
