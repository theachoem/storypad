import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

class BackupImagesUploaderService {
  String get cloudId => AssetDbModel.cloudId;

  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<bool> start(GoogleDriveClient client) async {
    debugPrint('🚧 $runtimeType#start ...');

    try {
      return await _start(client);
    } on exp.AuthException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      rethrow; // Let repository handle auth exceptions
    } on exp.NetworkException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      return false;
    } on exp.BackupException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      return false;
    } catch (e, stackTrace) {
      debugPrint('$runtimeType#start unexpected error: $e $stackTrace');
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: 'Failed to upload images due to unexpected error.',
        ),
      );
      return false;
    }
  }

  Future<bool> _start(GoogleDriveClient client) async {
    if (client.currentUser?.email == null) {
      throw const exp.AuthException(
        'No authenticated user for image upload',
        exp.AuthExceptionType.signInRequired,
      );
    }

    final List<AssetDbModel>? localAssets = await _getLocalAsset(client.currentUser!.email);
    if (localAssets == null || localAssets.isEmpty) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'No images to be uploaded.',
        ),
      );
      return true;
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));
    for (AssetDbModel asset in localAssets) {
      if (asset.localFile == null) continue;
      await _uploadAsset(client, asset);
    }

    controller.add(
      BackupSyncMessage(
        processing: false,
        success: true,
        message: '${localAssets.length} images uploaded successfully.',
      ),
    );

    return true;
  }

  Future<AssetDbModel?> _uploadAsset(GoogleDriveClient client, AssetDbModel asset) async {
    final cloudFileName = asset.cloudFileName;
    final String? email = client.currentUser?.email;

    if (cloudFileName == null || asset.localFile == null || email == null) {
      debugPrint('Skipping asset upload: missing required data');
      return null;
    }

    try {
      final cloudFile = await RetryExecutor.execute(
        () => client.uploadFile(
          cloudFileName,
          asset.localFile!,
          folderName: asset.type.subDirectory,
        ),
        policy: RetryPolicy.network,
        operationName: 'upload_asset_$cloudFileName',
      );

      if (cloudFile != null) {
        asset = asset.copyWithGoogleDriveCloudFile(cloudFile: cloudFile, email: email);
        return AssetDbModel.db.set(asset);
      }

      return null;
    } catch (e) {
      debugPrint('Failed to upload asset $cloudFileName: $e');
      // Don't rethrow - continue with other assets
      return null;
    }
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
