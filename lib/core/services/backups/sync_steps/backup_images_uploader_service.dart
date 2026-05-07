import 'dart:async';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

class BackupImagesUploaderService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<bool> start(BackupCloudService cloudService) async {
    AppLogger.d('🚧 $runtimeType#start ...');

    try {
      return await _start(cloudService);
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
      AppLogger.d('$runtimeType#start unexpected error: $e $stackTrace');
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

  Future<bool> _start(BackupCloudService cloudService) async {
    if (!cloudService.isSignedIn) {
      throw exp.AuthException(
        'Service ${cloudService.serviceType.displayName} is not signed in',
        exp.AuthExceptionType.signInRequired,
        serviceType: cloudService.serviceType,
      );
    }

    final uploadedCount = await _uploadAssetsForService(cloudService);

    if (uploadedCount > 0) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: '$uploadedCount images uploaded successfully.',
        ),
      );
    } else {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'No images to be uploaded.',
        ),
      );
    }

    return uploadedCount >= 0;
  }

  /// Upload all local assets that haven't been backed up to this service
  ///
  /// Returns: Number of assets successfully uploaded
  Future<int> _uploadAssetsForService(BackupCloudService cloudService) async {
    final List<AssetDbModel>? localAssets = await _getLocalAsset(cloudService);

    if (localAssets == null || localAssets.isEmpty) {
      return 0;
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    int uploadedCount = 0;
    for (AssetDbModel asset in localAssets) {
      if (asset.localFile == null) continue;
      final uploaded = await _uploadAsset(cloudService, asset);
      if (uploaded) uploadedCount++;
    }

    return uploadedCount;
  }

  /// Upload a single asset to the specified service with retry logic
  ///
  /// Returns: true if upload succeeded, false otherwise
  Future<bool> _uploadAsset(BackupCloudService cloudService, AssetDbModel asset) async {
    final cloudFileName = asset.cloudFileName;

    if (cloudFileName == null || asset.localFile == null) {
      AppLogger.d('Skipping asset upload: missing required data');
      return false;
    }

    try {
      final cloudFile = await RetryExecutor.execute(
        () => cloudService.uploadFile(
          cloudFileName,
          asset.localFile!,
          folderName: asset.type.subDirectory.relativePath,
        ),

        // Asset create is non-idempotent: retrying can create duplicate Drive files.
        policy: RetryPolicy.none,
        operationName: 'upload_asset_$cloudFileName',
      );

      if (cloudFile != null) {
        if (cloudService.currentUser?.identifier != null) {
          final updated = asset.copyWithCloudFile(
            serviceType: cloudService.serviceType,
            cloudFile: cloudFile,
            email: cloudService.currentUser!.identifier,
          );
          await AssetDbModel.db.set(updated);
        }

        AppLogger.d('Uploaded asset to ${cloudService.serviceType.displayName}: $cloudFileName');
        return true;
      }

      return false;
    } on exp.AuthException catch (e) {
      // Add service type to auth exception
      throw exp.AuthException(
        e.message,
        e.type,
        serviceType: cloudService.serviceType,
        context: e.context,
      );
    } catch (e) {
      AppLogger.d('Failed to upload asset $cloudFileName: $e');
      // Don't rethrow - continue with other assets
      return false;
    }
  }

  /// Get all local assets that haven't been backed up to this service
  ///
  /// Filters assets where:
  /// - cloudDestinations doesn't have this service, OR
  /// - cloudDestinations[service][email] is null
  /// - Local file exists
  ///
  /// Returns: List of assets needing backup
  Future<List<AssetDbModel>?> _getLocalAsset(BackupCloudService cloudService) async {
    CollectionDbModel<AssetDbModel>? assets = await AssetDbModel.db.where();

    if (cloudService.currentUser?.identifier != null) {
      return assets?.items
          .where(
            (e) =>
                e.cloudDestinations[cloudService.serviceType.id] == null ||
                e.cloudDestinations[cloudService.serviceType.id]?[cloudService.currentUser?.identifier] == null,
          )
          .toList()
          .where((e) => e.localFile?.existsSync() == true)
          .toList();
    } else {
      return assets?.items;
    }
  }
}
