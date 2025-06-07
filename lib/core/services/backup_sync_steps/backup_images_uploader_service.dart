import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';

class BackupImagesUploaderService {
  String get cloudId => AssetDbModel.cloudId;

  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<bool> start(GoogleDriveClient client) async {
    debugPrint('🚧 $runtimeType#start ...');

    return _start(client).onError((e, s) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Failed to upload images due to [error]',
      ));
      return false;
    });
  }

  Future<bool> _start(GoogleDriveClient client) async {
    if (client.currentUser?.email == null) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Sign in to continue.',
      ));
      return false;
    }

    final List<AssetDbModel>? localAssets = await _getLocalAsset(client.currentUser!.email);
    if (localAssets == null || localAssets.isEmpty) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: true,
        message: 'No images to be uploaded.',
      ));
      return true;
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));
    for (AssetDbModel asset in localAssets) {
      if (asset.localFile == null) continue;
      await _uploadAsset(client, asset);
    }

    controller.add(BackupSyncMessage(
      processing: false,
      success: true,
      message: '${localAssets.length} images uploaded successfully.',
    ));

    return true;
  }

  Future<AssetDbModel?> _uploadAsset(GoogleDriveClient client, AssetDbModel asset) async {
    final cloudFileName = asset.cloudFileName;
    final String? email = client.currentUser?.email;

    if (cloudFileName != null && asset.localFile != null && email != null) {
      final cloudFile = await client.uploadFile(
        cloudFileName,
        asset.localFile!,
        folderName: "images",
      );

      if (cloudFile != null) {
        asset = asset.copyWithGoogleDriveCloudFile(cloudFile: cloudFile, email: email);
        return AssetDbModel.db.set(asset);
      }
    }

    return null;
  }

  Future<List<AssetDbModel>?> _getLocalAsset(String email) async {
    CollectionDbModel<AssetDbModel>? assets = await AssetDbModel.db.where();
    return assets?.items
        .where((e) => e.cloudDestinations[cloudId] == null || e.cloudDestinations[cloudId]?[email] == null)
        .toList()
        .where((e) => e.localFile?.existsSync() == true)
        .toList();
  }
}
