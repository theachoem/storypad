import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpPurchaseSyncProviderSheet extends BaseBottomSheet {
  const SpPurchaseSyncProviderSheet();

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    final backupProvider = Provider.of<BackupProvider>(context);
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);
    final eligibleServices = backupProvider.services.where((s) => s.serviceType.hasGlobalUserId).toList();

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              buildTitle(context, tr('page.purchase_sync_provider.title')),
              const SizedBox(height: 4),
              buildSubtitle(
                context,
                // For future when multiple providers are supported.
                // tr('page.purchase_sync_provider.multiple_providers_message'),
                tr('page.purchase_sync_provider.single_provider_message'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ...eligibleServices.map((service) {
          return buildServiceTile(service, iapProvider, context, backupProvider);
        }),
        SizedBox(height: bottomPadding + 8),
      ],
    );
  }

  Widget buildTitle(BuildContext context, String title) {
    return Text.rich(
      TextSpan(
        text: '$title ',
        style: TextTheme.of(context).titleMedium,
        children: [
          WidgetSpan(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ColorScheme.of(context).outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                child: Text(
                  tr('general.optional'),
                  style: TextTheme.of(context).labelSmall?.copyWith(
                    color: ColorScheme.of(context).onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSubtitle(BuildContext context, String subtitle) {
    return Text(
      subtitle,
      style: TextTheme.of(context).bodyMedium?.copyWith(
        color: ColorScheme.of(context).onSurfaceVariant,
      ),
    );
  }

  Widget buildServiceTile(
    BackupCloudService service,
    InAppPurchaseProvider iapProvider,
    BuildContext context,
    BackupProvider backupProvider,
  ) {
    final isSignedIn = service.isSignedIn;
    final user = service.currentUser;
    final isSelected = iapProvider.selectedSyncProvider == service.serviceType;

    Widget leading = CircleAvatar(
      radius: 16,
      backgroundImage: isSignedIn && user?.photoUrl != null ? CachedNetworkImageProvider(user!.photoUrl!) : null,
      child: isSignedIn && user?.photoUrl != null ? null : Icon(service.serviceType.icon, size: 16),
    );

    Widget? trailing = isSignedIn
        ? isSelected
              ? SpFadeIn.fromBottom(child: Icon(SpIcons.checkCircle, color: ColorScheme.of(context).primary))
              : null
        : FilledButton.tonal(
            onPressed: () async {
              await backupProvider.signIn(context, service.serviceType);

              // Disable auto-backup when connecting via this sheet to avoid unintended backups.
              // Users connecting here are doing so for purchase sync, not backup.
              backupProvider.repository.getService(service.serviceType).setAutoBackupEnabled(false);
            },
            child: Text(tr('button.connect')),
          );

    return ListTile(
      leading: leading,
      title: Text(service.serviceType.displayName),
      subtitle: isSignedIn && user != null
          ? Text(
              user.displayName ?? user.identifier,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
      onTap: isSignedIn ? () => iapProvider.setSelectedPurchaseSyncProvider(service.serviceType) : null,
    );
  }
}
