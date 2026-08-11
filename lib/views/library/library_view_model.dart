import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'library_view.dart';

class LibraryViewModel extends ChangeNotifier with DisposeAwareMixin {
  final LibraryRoute params;

  LibraryViewModel({
    required this.params,
  });

  Future<void> deleteAsset(BuildContext context, AssetDbModel asset, int storyCount) async {
    // This is important as user could just recently deleted the story with this asset in it which show a snack to undo.
    // So if we don't clear it, it will show the snack bar, user can restore back the story, but the asset will still be deleted.
    // This is rare case, but still important to handle.
    MessengerService.of(context).clearSnackBars();

    final bool hasInternet = await InternetCheckerService().check();
    if (!context.mounted) return;

    if (!hasInternet) {
      MessengerService.of(context).showSnackBar(tr('snack_bar.no_internet'));
      return;
    }

    OkCancelResult userAction = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: tr('dialog.are_you_sure.title'),
      message: tr('dialog.are_you_sure.you_cant_undo_message'),
      okLabel: tr('button.delete'),
      cancelLabel: tr('button.cancel'),
    );

    if (userAction == OkCancelResult.ok && context.mounted) {
      await MessengerService.of(context).showLoading(
        debugSource: 'LibraryViewModel#deleteAsset',
        future: () => _deleteAsset(context, asset, storyCount),
      );
    }
  }

  Future<bool> _deleteAsset(BuildContext context, AssetDbModel asset, int storyCount) async {
    AnalyticsService.instance.logDeleteAsset(asset: asset);

    final destinations = asset.allCloudDestinations;

    // Never uploaded anywhere — safe to delete locally right away.
    if (destinations.isEmpty) {
      await asset.delete();
      return true;
    }

    final provider = context.read<BackupProvider>();

    // Every destination (across every service, not just Drive) must be
    // deleted — or already confirmed gone via 404 — before the local record
    // goes. Losing the local copy while a remote one still exists would
    // orphan it with no way to find it again.
    for (final destination in destinations) {
      final service = provider.repository.getService(destination.serviceType);

      // A destination is scoped to a specific account/folder (destinationKey),
      // not just a provider — if the user switched accounts (Drive) or
      // reconnected under a different folder (Nextcloud) since this asset was
      // uploaded, the currently signed-in credential is the *wrong* one for
      // this destination, and there's no credential retained for the old
      // one to delete it properly. This must NOT fall through to deleting
      // the local record below: doing so would silently orphan the still-live
      // remote copy with no trace left to ever find it again. Report it as
      // undeleted, same as any other destination that couldn't be confirmed
      // gone — the user sees the item wasn't removed rather than losing the
      // only record of where it lives.
      if (destination.identifier != service.currentUser?.destinationKey) {
        AppLogger.d(
          'LibraryViewModel#_deleteAsset: cannot delete asset ${asset.id} on '
          '${destination.serviceType.displayName} — destination ${destination.identifier} does not match the '
          'currently signed-in account (${service.currentUser?.destinationKey}).',
        );
        return false;
      }

      bool deleted = false;
      bool notFound = false;

      try {
        deleted = await service.deleteFile(destination.fileId);
      } catch (e) {
        if (e is exp.FileOperationException) {
          notFound = e.statusCode == 404;
        }
      }

      if (!deleted && !notFound) return false;
    }

    await asset.delete();
    return true;
  }
}
