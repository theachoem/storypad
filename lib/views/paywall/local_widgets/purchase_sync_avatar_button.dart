part of '../paywall_view.dart';

class _PurchaseSyncAvatarButton extends StatelessWidget {
  const _PurchaseSyncAvatarButton();

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);
    final backupProvider = Provider.of<BackupProvider>(context);

    final services = backupProvider.services;
    final selectedService = services
        .where((s) => s.serviceType == iapProvider.selectedSyncProvider && s.isSignedIn)
        .firstOrNull;
    final photoUrl = selectedService?.currentUser?.photoUrl;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () => const SpPurchaseSyncProviderSheet().show(context: context),
        child: CircleAvatar(
          radius: 16,
          backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
          child: photoUrl == null ? const Icon(SpIcons.cloudOff, size: 20) : null,
        ),
      ),
    );
  }
}
