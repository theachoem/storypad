import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'library_view.dart';

class LibraryViewModel extends ChangeNotifier with DisposeAwareMixin {
  final LibraryRoute params;

  LibraryViewModel({
    required this.params,
  }) {
    load();

    StoryDbModel.db.addGlobalListener(() async {
      load();
    });
  }

  Map<int, int> storiesCount = {};
  CollectionDbModel<AssetDbModel>? assets;

  Future<void> load() async {
    assets = await AssetDbModel.db.where(
      filters: {
        'type': AssetType.image,
      },
    );

    for (var asset in assets?.items ?? <AssetDbModel>[]) {
      storiesCount[asset.id] = await StoryDbModel.db.count(
        filters: {
          'asset': asset.id,
        },
      );
    }

    notifyListeners();
  }

  Future<void> deleteAsset(BuildContext context, AssetDbModel asset, int storyCount) async {
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
      assets = assets?.removeElement(asset);
      notifyListeners();
      return true;
    }

    if (provider.currentUser?.email == null) return false;
    final fileId = asset.getGoogleDriveIdForEmail(provider.currentUser!.email);

    if (fileId != null) {
      bool? deleted;
      int? statusCode;

      try {
        deleted = await provider.repository.googleDriveClient.deleteFile(fileId);
      } catch (e) {
        if (e is drive.DetailedApiRequestError) {
          statusCode = e.status;
        }
      }

      if (statusCode == 404 || deleted == true) {
        await asset.delete();
        assets = assets?.removeElement(asset);
        notifyListeners();
        return true;
      }
    } else {
      // Allow delete db asset when no file ID for current email found.
      await asset.delete();
      assets = assets?.removeElement(asset);
      notifyListeners();
      return true;
    }

    return false;
  }
}
