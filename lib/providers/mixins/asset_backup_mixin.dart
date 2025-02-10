// ignore_for_file: library_private_types_in_public_api

part of '../backup_provider.dart';

mixin _AssetBackupConcern on _BaseBackupProvider {
  CollectionDbModel<AssetDbModel>? assets;
  List<AssetDbModel>? localAssets;
  ValueNotifier<int?> loadingAssetIdNotifier = ValueNotifier(null);

  Future<void> _loadAssets() async {
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

    await _loadAssets();
    debugPrint('🚧 $runtimeType#uploadAssets -> Done with remain un-uploaded assets: ${localAssets?.length}');
    notifyListeners();
  }

  Future<void> deleteAsset(AssetDbModel asset) async {
    if (source.email == null) return;
    final fileId = asset.getGoogleDriveIdForEmail(source.email!);

    if (fileId != null) {
      loadingAssetIdNotifier.value = asset.id;
      final deleledFile = await source.deleteCloudFile(fileId);

      if (deleledFile != null) {
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

  @override
  void dispose() {
    loadingAssetIdNotifier.dispose();
    super.dispose();
  }
}
