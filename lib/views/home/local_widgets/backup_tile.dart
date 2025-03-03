import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/backup_view.dart';

class BackupTile extends StatefulWidget {
  const BackupTile({
    super.key,
  });

  @override
  State<BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends State<BackupTile> {
  bool focusing = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);

    if (provider.source.isSignedIn == true) {
      return _SignedInTile(provider: provider);
    } else {
      return _UnsignInTile(provider: provider);
    }
  }
}

class _UnsignInTile extends StatelessWidget {
  const _UnsignInTile({
    required this.provider,
  });

  final BackupProvider provider;

  Future<void> signIn(BuildContext context, BackupProvider provider) {
    return provider.signIn(
      context: context,
      showLoading: true,
      debugSource: '$runtimeType#signIn',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0.0,
      children: [
        ListTile(
          onTap: () => BackupRoute().push(context),
          leading: Icon(Icons.backup_outlined),
          title: Text(tr('list_tile.backup.title')),
          subtitle: Text(tr('list_tile.backup.unsignin_subtitle')),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
        ),
        Container(
          margin: const EdgeInsets.only(left: 52.0),
          transform: Matrix4.identity()..translate(0.0, -8.0),
          child: FilledButton.icon(
            icon: Icon(MdiIcons.googleDrive),
            label: Text(tr("button.sign_in")),
            onPressed: () => signIn(context, provider),
          ),
        )
      ],
    );
  }
}

class _SignedInTile extends StatelessWidget {
  const _SignedInTile({
    required this.provider,
  });

  final BackupProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTile(context),
        if (!provider.syncing &&
            !provider.synced &&
            (provider.lastDbUpdatedAt != null || provider.lastSyncedAt != null))
          buildSyncButton(context),
      ],
    );
  }

  Widget buildTile(BuildContext context) {
    Widget leading;
    Widget? subtitle;

    if (provider.syncing) {
      leading = const SizedBox.square(
        dimension: 24.0,
        child: CircularProgressIndicator.adaptive(),
      );
      subtitle = Text(tr("general.syncing"));
    } else if (provider.synced) {
      leading = Icon(
        Icons.cloud_done,
        color: ColorScheme.of(context).bootstrap.success.color,
      );
      subtitle = Text(DateFormatHelper.yMEd_jmNullable(provider.lastSyncedAt, context.locale) ?? '...');
    } else if (provider.lastDbUpdatedAt != null) {
      String? deviceModel = provider.syncedFile?.getFileInfo()?.device.model;

      String fallbackMessage = [
        if (deviceModel != null) deviceModel,
        if (provider.lastSyncedAt != null) DateFormatHelper.yMEd_jmNullable(provider.lastSyncedAt, context.locale),
      ].join(", ");

      if (fallbackMessage.isEmpty && provider.source.email != null) {
        fallbackMessage = provider.source.email!;
      }

      leading = const Icon(Icons.cloud_upload_outlined);
      subtitle = provider.canBackup() ? Text(tr("list_tile.backup.some_data_has_not_sync_subtitle")) : null;

      if (subtitle == null && fallbackMessage.isNotEmpty) subtitle = Text(fallbackMessage);
    } else {
      leading = const Icon(Icons.cloud_upload_outlined);
      subtitle = Text(provider.source.email ?? tr("general.na"));
    }

    if (provider.source.smallImageUrl != null) {
      leading = Transform.scale(
        scale: 1.5,
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(provider.source.smallImageUrl!),
          radius: 12.0,
        ),
      );
    }

    return FutureBuilder(
      future: Future.delayed(Durations.long4).then((value) => 1),
      builder: (context, snapshot) {
        bool focusDisabled = provider.synced || snapshot.data == 1;

        return AnimatedContainer(
          duration: const Duration(seconds: 1),
          curve: Curves.ease,
          color: focusDisabled
              ? Theme.of(context).scaffoldBackgroundColor
              : ColorScheme.of(context).primary.withValues(alpha: 0.1),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: leading,
              onTap: () => BackupRoute().push(context),
              subtitle: subtitle,
              title: RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(
                  text: "${tr("list_tile.backup.title")} ",
                  style: TextTheme.of(context).bodyLarge,
                  children: [
                    if (provider.synced)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.cloud_done,
                          color: ColorScheme.of(context).bootstrap.success.color,
                          size: 16.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSyncButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 52.0),
      transform: Matrix4.identity()..translate(0.0, -8.0),
      child: OutlinedButton.icon(
        label: Text(tr("button.sync")),
        onPressed: provider.syncing ? null : () => provider.syncBackupAcrossDevices(context),
      ),
    );
  }
}
