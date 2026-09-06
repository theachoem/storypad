import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/backup_sync_state_store.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/backup_services/show/show_backup_service_view.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/views/settings/data_backup/data_backup_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

class BackupTile extends StatelessWidget {
  // No need const constructor for translation to work properly.
  // ignore: prefer_const_constructors_in_immutables
  BackupTile({
    super.key,
    required this.onNavigate,
  });

  final void Function(BaseRoute route) onNavigate;

  @override
  Widget build(BuildContext context) {
    BackupProvider provider = Provider.of<BackupProvider>(context);
    final isProUser = Provider.of<InAppPurchaseProvider>(context).isProUser;

    Widget leading;
    Widget title = const Text("...");
    Widget subtitle = const Text("...");
    Widget? action;

    // Mirrors the entitlement filter BackupProvider.recheckAndSync applies
    // internally (Pro-only services never actually sync for a free user) —
    // without this, a free user connected only to Nextcloud/iCloud would see
    // this tile's status/actions driven by a service that can never sync,
    // including a Retry/Refresh/Sync button that silently does nothing.
    final eligibleServices = provider.services
        .where((service) => service.isSignedIn && (isProUser || !service.serviceType.isProOnly))
        .toList();
    final aggregateStatus = eligibleServices.isNotEmpty ? _aggregateConnectionStatus(eligibleServices, provider) : null;

    if (!provider.isSignedIn) {
      leading = const Icon(SpIcons.cloudOff);
      title = Text(tr("list_tile.backup.title"));
      subtitle = Text(tr('list_tile.backup.unsignin_subtitle'));
      action = FilledButton.icon(
        icon: const Icon(SpIcons.cloudUpload),
        label: Text(tr('button.connect')),
        onPressed: () => onNavigate(const DataBackupRoute()),
      );
    } else if (eligibleServices.isEmpty) {
      // Signed into something (e.g. Nextcloud/iCloud via the purchase-sync
      // sheet), but nothing entitled to actually sync — route to the paywall
      // instead of a dead-end Retry/Refresh/Sync action.
      leading = const Icon(SpIcons.lock);
      title = Text(tr("list_tile.backup.title"));
      subtitle = Text(tr('list_tile.upgrade_to_pro.subtitle'));
      action = FilledButton.icon(
        icon: const Icon(SpIcons.starCircle),
        label: Text(tr('list_tile.upgrade_to_pro.title')),
        onPressed: () => onNavigate(const PaywallRoute(initialFocus: .multi_cloud_sync)),
      );
    } else {
      switch (aggregateStatus) {
        case .unknownError:
          leading = const Icon(SpIcons.cloudOff);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.unknown_error'));
          action = FilledButton.icon(
            icon: const Icon(SpIcons.refresh),
            label: Text(tr('button.retry')),
            onPressed: () => provider.recheckAndSync(services: eligibleServices, context: context),
          );
          break;
        case .noInternet:
          leading = const Icon(SpIcons.cloudOff);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.no_internet_subtitle'));
          action = FilledButton.icon(
            icon: const Icon(SpIcons.refresh),
            label: Text(tr('button.refresh')),
            onPressed: () => provider.recheckAndSync(services: eligibleServices, context: context),
          );
          break;
        case .needServicePermission:
          leading = const Icon(SpIcons.cloudOff);
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.no_permission_subtitle'));
          action = FilledButton.icon(
            icon: const Icon(SpIcons.warning),
            label: Text(tr('button.fix_connection')),
            onPressed: () => onNavigate(
              ShowBackupServiceRoute(
                service: _serviceWithStatus(eligibleServices, provider, BackupConnectionStatus.needServicePermission),
              ),
            ),
          );
          break;
        case .readyToSync:
          leading = Icon(_connectedServiceIcon(eligibleServices));
          title = Text(tr("list_tile.backup.title"));
          subtitle = Text(tr('list_tile.backup.some_data_has_not_sync_subtitle'));
          action = FilledButton(
            child: Text(tr('button.sync')),
            onPressed: () => provider.recheckAndSync(services: eligibleServices, context: context),
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

    // Don't let a global "all years synced" flag paint a success state over
    // a real per-service problem — e.g. a previously-synced Drive plus a
    // revoked Nextcloud credential can still leave allYearSynced true, since
    // it only tracks year-file freshness, not per-service connection health.
    // pendingMediaCount is tracked separately for the same reason: media
    // deferred by the Wi-Fi-only setting doesn't move allYearSynced either.
    if (aggregateStatus == BackupConnectionStatus.readyToSync &&
        provider.allYearSynced &&
        provider.pendingMediaCount == 0) {
      leading = Icon(_connectedServiceIcon(eligibleServices));
      subtitle = Text(DateFormatHelper.yMEd_jmNullable(provider.lastSyncedAt, context.locale) ?? '...');
      action = null;
      title = Text.rich(
        TextSpan(
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
      subtitle = Text(tr("general.syncing"));
      action = null;

      final progress = _overallSyncProgress(eligibleServices, provider);
      if (progress != null) subtitle = Text("${tr("general.syncing")} ${progress.current}/${progress.total}");

      title = Text.rich(
        TextSpan(
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

    String? photoUrl = _firstAvailablePhotoUrl(provider);
    if (photoUrl != null) {
      leading = Transform.scale(
        scale: 1.5,
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(photoUrl),
          onBackgroundImageError: (_, _) {},
          radius: 12.0,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: () => onNavigate.call(const DataBackupRoute()),
          leading: leading,
          title: title,
          subtitle: subtitle,
        ),
        if (action != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 52.0),
            child: action,
          ),
          const SizedBox(height: 4.0),
        ],
      ],
    );
  }

  BackupCloudService? _firstSignedInService(List<BackupCloudService> services) {
    for (final service in services) {
      if (service.isSignedIn) return service;
    }
    return null;
  }

  String? _firstAvailablePhotoUrl(BackupProvider provider) {
    for (final user in provider.availableUsers) {
      if (user.photoUrl != null) return user.photoUrl;
    }
    return null;
  }

  IconData _connectedServiceIcon(List<BackupCloudService> services) {
    return _firstSignedInService(services)?.serviceType.icon ?? SpIcons.cloudDone;
  }

  /// Worst-case-wins summary across every signed-in service's own connection
  /// status (`provider.statusFor(type).connectionStatus`) — a problem on any
  /// one of them surfaces here, in order of how actionable it is to the user.
  /// Null means every signed-in service is still being checked. [services]
  /// must already be entitlement-filtered by the caller (see the
  /// `eligibleServices` local in [build]) so a locked Nextcloud/iCloud
  /// connection can't drive this tile's status/actions for a free user.
  BackupConnectionStatus? _aggregateConnectionStatus(List<BackupCloudService> services, BackupProvider provider) {
    final signedInTypes = services.where((s) => s.isSignedIn).map((s) => s.serviceType).toList();
    if (signedInTypes.isEmpty) return null;

    const priority = [
      BackupConnectionStatus.needServicePermission,
      BackupConnectionStatus.unknownError,
      BackupConnectionStatus.noInternet,
    ];

    for (final candidate in priority) {
      if (signedInTypes.any((type) => provider.statusFor(type).connectionStatus == candidate)) {
        return candidate;
      }
    }

    final allReady = signedInTypes.every(
      (type) => provider.statusFor(type).connectionStatus == BackupConnectionStatus.readyToSync,
    );
    return allReady ? BackupConnectionStatus.readyToSync : null;
  }

  /// Which service's detail page to open when the aggregate status needs
  /// attention. Falls back to the first connected service if none matches —
  /// this branch only runs when at least one service is signed in.
  BackupCloudService _serviceWithStatus(
    List<BackupCloudService> services,
    BackupProvider provider,
    BackupConnectionStatus status,
  ) {
    for (final service in services) {
      if (service.isSignedIn && provider.statusFor(service.serviceType).connectionStatus == status) return service;
    }
    return _firstSignedInService(services) ?? services.first;
  }

  /// Combines every signed-in service's 4 steps into one running count, so
  /// syncing e.g. 2 services shows 1/8..8/8 instead of restarting at 1/4 for
  /// each service in turn. Sync runs sequentially through provider.services
  /// (see BackupProvider._syncBackupAcrossDevices), so a signed-in service
  /// earlier in that order than the currently active one has already
  /// completed all 4 of its own steps.
  ({int current, int total})? _overallSyncProgress(List<BackupCloudService> services, BackupProvider provider) {
    final signedIn = provider.services.where((service) => service.isSignedIn).toList();
    if (signedIn.isEmpty) return null;

    for (var i = 0; i < signedIn.length; i++) {
      final status = provider.statusFor(signedIn[i].serviceType);
      final step = status.currentStep;
      if (status.activity == SyncActivity.active && step != null) {
        return (current: i * 4 + step.stepNumber, total: signedIn.length * 4);
      }
    }
    return null;
  }
}
