import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
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

    final provider = context.read<BackupProvider>();

    // Only destinations on a currently signed-in account/folder are
    // reachable from this device — a destination on a provider this device
    // isn't connected to (or reconnected under a different account/folder)
    // can't be deleted here. Those are skipped rather than blocking the
    // whole operation: Cloud Optimize's detached-file cleanup already
    // identifies remote files with no live local record (by parsing the
    // asset id out of the filename, independent of cloudDestinations) and
    // trashes them after a grace period, so an unreachable leftover gets
    // caught the next time this asset's other provider is connected and
    // Optimize runs there.
    final destinations = asset.matchingCloudDestinationsFor(provider.signedInServices);

    for (final destination in destinations) {
      final service = provider.repository.getService(destination.serviceType);

      bool deleted = false;
      bool notFound = false;

      try {
        deleted = await service.deleteFile(destination.fileId);
      } catch (e) {
        if (e is exp.FileOperationException) {
          notFound = e.statusCode == 404;
        }
      }

      // A destination we ARE connected to that still failed (not a
      // confirmed 404) is a real failure, not an unreachable-provider case
      // — still worth reporting as undeleted.
      if (!deleted && !notFound) return false;
    }

    await asset.delete();
    return true;
  }
}
