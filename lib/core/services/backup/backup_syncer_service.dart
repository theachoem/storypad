import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backup/google_drive_client_service.dart';
import 'package:storypad/core/services/backup_sources/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backup_sources/backup_to_file_service.dart';
import 'package:storypad/core/services/backups/restore_backup_service.dart';

class BackupSyncerService {
  final GoogleDriveClientService _driveClientService;

  static String get cloudProviderId => "google_drive";
  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
    TemplateDbModel.db,
    AssetDbModel.db,
  ];

  BackupSyncerService(this._driveClientService);

  Future<(bool, CloudFileObject?)> checkShouldSyncFromCloud() async {
    CloudFileObject? syncedFile = await _driveClientService.getLastestBackupFile();
    DateTime? lastDbUpdatedAt = await _getLastDbUpdatedAt();

    DateTime? lastSyncedAt = syncedFile?.getFileInfo()?.createdAt;
    bool shouldSyncFromCloud = lastSyncedAt != null && lastSyncedAt != lastDbUpdatedAt;

    return (shouldSyncFromCloud, syncedFile);
  }

  Future<bool> checkShouldBackup(CloudFileObject? lastestCloudFile) async {
    DateTime? lastSyncedAt = lastestCloudFile?.getFileInfo()?.createdAt;
    DateTime? lastDbUpdatedAt = await _getLastDbUpdatedAt();
    bool storyEmpty = await StoryDbModel.db.count() == 0;

    return !storyEmpty && lastDbUpdatedAt != null && lastDbUpdatedAt != lastSyncedAt;
  }

  Future<BackupObject?> getBackupFromCloudFile(CloudFileObject cloudFile) async {
    final backupContents = await _driveClientService.getFileContent(cloudFile);
    if (backupContents != null) {
      try {
        final decoded = jsonDecode(backupContents);
        return BackupObject.fromContents(decoded);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  Future<bool> restoreLatestBackupFromCloud(CloudFileObject lastestCloudFile) async {
    final backup = await getBackupFromCloudFile(lastestCloudFile);
    if (backup == null) return false;

    await RestoreBackupService.instance.restoreOnlyNewData(backup: backup);
    return true;
  }

  Future<bool> deleteCloudFile(String fileId) async {
    // if 404 return true
    return false;
  }

  Future<bool> uploadAssets(String email) async {
    CollectionDbModel<AssetDbModel>? assets = await AssetDbModel.db.where();
    List<AssetDbModel>? localAssets = assets?.items
        .where(
            (e) => e.cloudDestinations[cloudProviderId] == null || e.cloudDestinations[cloudProviderId]?[email] == null)
        .toList()
        .where((e) => e.localFile?.existsSync() == true)
        .toList();

    if (localAssets == null || localAssets.isEmpty) return true;

    for (AssetDbModel asset in [...localAssets]) {
      if (asset.localFile == null) continue;

      final cloudFileName = asset.cloudFileName;

      AssetDbModel? uploadedAsset;
      if (cloudFileName != null && asset.localFile != null) {
        final cloudFile = await _driveClientService.uploadFile(
          cloudFileName,
          asset.localFile!,
          folderName: "images",
        );

        if (cloudFile != null) {
          asset = asset.copyWithGoogleDriveCloudFile(cloudFile: cloudFile);
          uploadedAsset = await AssetDbModel.db.set(asset);
        }
      }

      if (uploadedAsset != null) {
        assets = assets?.replaceElement(uploadedAsset);
        localAssets.removeWhere((e) => e.id == uploadedAsset!.id);
      }
    }

    return (await AssetDbModel.db.where())
            ?.items
            .where((e) =>
                e.cloudDestinations[cloudProviderId] == null || e.cloudDestinations[cloudProviderId]?[email] == null)
            .toList()
            .where((e) => e.localFile?.existsSync() == true)
            .toList()
            .isEmpty ==
        true;
  }

  /// call [checkShouldBackup] before calling this method
  /// to avoid lastDbUpdatedAt null error.
  Future<void> uploadBackupFromThisDevice() async {
    DateTime lastDbUpdatedAt = await _getLastDbUpdatedAt().then((e) => e!);

    final backup = await BackupDatabasesToBackupObjectService.call(
      databases: databases,
      lastUpdatedAt: lastDbUpdatedAt,
    );

    final io.File file = await BackupToFileService.call(
      cloudProviderId,
      backup,
    );

    await _driveClientService.uploadFile(backup.fileInfo.fileNameWithExtention, file);
  }

  Future<DateTime?> _getLastDbUpdatedAt() async {
    DateTime? updatedAt;

    for (var db in databases) {
      DateTime? newUpdatedAt = await db.getLastUpdatedAt();
      if (newUpdatedAt == null) continue;

      if (updatedAt != null) {
        if (newUpdatedAt.isBefore(updatedAt)) continue;
        updatedAt = newUpdatedAt;
      } else {
        updatedAt = newUpdatedAt;
      }
    }

    return updatedAt;
  }
}
