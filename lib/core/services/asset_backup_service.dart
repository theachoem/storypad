import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/services/backup_sources/google_drive_backup_source.dart';

class AssetBackupService {
  final void Function() notifyListeners;
  final GoogleDriveBackupSource source;

  AssetBackupService({
    required this.notifyListeners,
    required this.source,
  });

  CollectionDbModel<AssetDbModel>? assets;
  List<AssetDbModel>? localAssets;
  ValueNotifier<int?> loadingAssetIdNotifier = ValueNotifier(null);

  Future<void> loadAssets() async {
    assets = await AssetDbModel.db.where();

    final items = assets?.items ?? [];
    final cloudId = source.cloudId;
    final email = source.email;

    localAssets = await Isolate.run(() {
      return items.where((e) {
        return e.cloudDestinations[cloudId] == null || e.cloudDestinations[cloudId]?[email] == null;
      }).toList();
    });

    localAssets = localAssets?.where((e) => e.localFile?.existsSync() == true).toList();
  }

  Future<void> uploadAssets() async {
    debugPrint('🚧 $runtimeType#uploadAssets ...');

    if (localAssets == null || localAssets!.isEmpty) return;
    for (AssetDbModel asset in [...localAssets!]) {
      if (asset.localFile == null) continue;

      loadingAssetIdNotifier.value = asset.id;
      AssetDbModel? uploadedAsset = await uploadAsset(asset);
      loadingAssetIdNotifier.value = null;

      if (uploadedAsset != null) {
        assets = assets?.replaceElement(uploadedAsset);
        localAssets!.removeWhere((e) => e.id == uploadedAsset.id);
      }
    }

    await loadAssets();
    debugPrint('🚧 $runtimeType#uploadAssets -> Done with remain un-uploaded assets: ${localAssets?.length}');
    notifyListeners();
  }

  Future<void> deleteAsset(AssetDbModel asset, int storyCount) async {
    final uploadedEmails = asset.getGoogleDriveForEmails() ?? [];

    // when image is not yet upload, allow delete locally.
    if (uploadedEmails.isEmpty || storyCount == 0) {
      await asset.delete();
      notifyListeners();
      return;
    }

    if (source.email == null) return;
    final fileId = asset.getGoogleDriveIdForEmail(source.email!);

    if (fileId != null) {
      loadingAssetIdNotifier.value = asset.id;
      final deleledFile = await source.deleteCloudFile(fileId);

      if (source.lastRequestStatusCode == 404 || deleledFile != null) {
        await asset.delete();
        assets = assets?.removeElement(asset);
      }

      loadingAssetIdNotifier.value = null;
      notifyListeners();
    }
  }

  Future<AssetDbModel?> uploadAsset(AssetDbModel asset) async {
    final cloudFileName = asset.cloudFileName;

    if (cloudFileName != null && asset.localFile != null) {
      final cloudFile = await source.uploadFile(
        cloudFileName,
        asset.localFile!,
        folderName: "images",
      );

      if (cloudFile != null) {
        asset = asset.copyWithGoogleDriveCloudFile(cloudFile: cloudFile);
        return AssetDbModel.db.set(asset);
      }
    }

    return null;
  }

  void dispose() => loadingAssetIdNotifier.dispose();
}
