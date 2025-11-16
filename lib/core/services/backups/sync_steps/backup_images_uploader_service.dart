import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

class BackupImagesUploaderService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<bool> start(List<BackupCloudService> services) async {
    debugPrint('🚧 $runtimeType#start ...');

    try {
      return await _start(services);
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

  Future<bool> _start(List<BackupCloudService> services) async {
    if (services.isEmpty) {
      throw const exp.AuthException(
        'No backup services available for image upload',
        exp.AuthExceptionType.signInRequired,
        serviceType: null,
      );
    }

    // Collect uploads from all services
    bool allSuccess = true;
    int totalUploaded = 0;

    for (final service in services) {
      if (!service.isSignedIn || service.currentUser?.email == null) {
        debugPrint('Skipping service ${service.serviceType.displayName}: not signed in');
        continue;
      }

      final uploadedCount = await _uploadAssetsForService(service);
      totalUploaded += uploadedCount;

      if (uploadedCount < 0) {
        allSuccess = false;
      }
    }

    if (totalUploaded > 0) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: '$totalUploaded images uploaded successfully across all services.',
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

    return allSuccess;
  }

  Future<int> _uploadAssetsForService(BackupCloudService service) async {
    final email = service.currentUser!.email;
    final List<AssetDbModel>? localAssets = await _getLocalAsset(email, service.serviceType);

    if (localAssets == null || localAssets.isEmpty) {
      return 0;
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    int uploadedCount = 0;
    for (AssetDbModel asset in localAssets) {
      if (asset.localFile == null) continue;
      final uploaded = await _uploadAsset(service, asset);
      if (uploaded) uploadedCount++;
    }

    return uploadedCount;
  }

  Future<bool> _uploadAsset(BackupCloudService service, AssetDbModel asset) async {
    final cloudFileName = asset.cloudFileName;
    final String? email = service.currentUser?.email;

    if (cloudFileName == null || asset.localFile == null || email == null) {
      debugPrint('Skipping asset upload: missing required data');
      return false;
    }

    try {
      final cloudFile = await RetryExecutor.execute(
        () => service.uploadFile(
          cloudFileName,
          asset.localFile!,
          folderName: asset.type.subDirectory,
        ),
        policy: RetryPolicy.network,
        operationName: 'upload_asset_$cloudFileName',
      );

      if (cloudFile != null) {
        final updated = asset.copyWithCloudFile(
          serviceType: service.serviceType,
          cloudFile: cloudFile,
          email: email,
        );
        await AssetDbModel.db.set(updated);
        return true;
      }

      return false;
    } on exp.AuthException catch (e) {
      // Add service type to auth exception
      throw exp.AuthException(
        e.message,
        e.type,
        serviceType: service.serviceType,
        context: e.context,
      );
    } catch (e) {
      debugPrint('Failed to upload asset $cloudFileName: $e');
      // Don't rethrow - continue with other assets
      return false;
    }
  }

  Future<List<AssetDbModel>?> _getLocalAsset(String email, BackupServiceType serviceType) async {
    CollectionDbModel<AssetDbModel>? assets = await AssetDbModel.db.where();
    return assets?.items
        .where(
          (e) => e.cloudDestinations[serviceType.id] == null || e.cloudDestinations[serviceType.id]?[email] == null,
        )
        .toList()
        .where((e) => e.localFile?.existsSync() == true)
        .toList();
  }
}
