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
    final uploadedEmails = asset.getGoogleDriveForEmails() ?? [];

    // when image is not yet upload, allow delete locally.
    if (uploadedEmails.isEmpty) {
      await asset.delete();
      return true;
    }

    if (provider.currentUser?.email == null) return false;
    final fileId = asset.getGoogleDriveIdForEmail(provider.currentUser!.email);

    if (fileId != null) {
      bool? deleted;
      bool? notFound;

      try {
        deleted = await provider.repository.googleDriveService.deleteFile(fileId);
      } catch (e) {
        if (e is exp.FileOperationException) {
          notFound = e.statusCode == 404;
        }
      }

      if (notFound == true || deleted == true) {
        await asset.delete();
        return true;
      }
    } else {
      // Allow delete db asset when no file ID for current email found.
      await asset.delete();
      return true;
    }

    return false;
  }
}
