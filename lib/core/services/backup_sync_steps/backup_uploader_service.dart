import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/gzip_service.dart';
import 'package:storypad/core/types/file_path_type.dart';

class BackupUploaderResponse {
  final bool hasError;
  final CloudFileObject? uploadedCloudFile;

  BackupUploaderResponse({
    required this.hasError,
    required this.uploadedCloudFile,
  });
}

class BackupUploaderService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<BackupUploaderResponse> start(
    GoogleDriveClient client,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  ) async {
    try {
      if (lastDbUpdatedAt == null || lastSyncedAt == lastDbUpdatedAt) {
        controller.add(BackupSyncMessage(
          processing: false,
          success: true,
          message: 'No new stories to upload.',
        ));

        return BackupUploaderResponse(
          hasError: false,
          uploadedCloudFile: null,
        );
      }

      return _start(client, lastDbUpdatedAt);
    } catch (error) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Failed to upload new stories due to [$error]',
      ));

      return BackupUploaderResponse(
        hasError: true,
        uploadedCloudFile: null,
      );
    }
  }

  Future<BackupUploaderResponse> _start(GoogleDriveClient client, DateTime lastDbUpdatedAt) async {
    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    BackupObject backup = await BackupDatabasesToBackupObjectService.call(
      databases: BackupRepository.databases,
      lastUpdatedAt: lastDbUpdatedAt,
    );

    final io.File file = await constructBackupFile(
      AssetDbModel.cloudId,
      backup,
    );

    final uploadedFile = await client.uploadFile(
      backup.fileInfo.fileNameWithExtention,
      file,
    );

    if (uploadedFile != null) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: true,
        message: 'All new stories uploaded successfully.',
      ));

      return BackupUploaderResponse(
        hasError: false,
        uploadedCloudFile: uploadedFile,
      );
    }

    controller.add(BackupSyncMessage(
      processing: false,
      success: false,
      message: 'Failed to upload new stories due to [Unknown]',
    ));

    return BackupUploaderResponse(
      hasError: true,
      uploadedCloudFile: null,
    );
  }

  Future<io.File> constructBackupFile(
    String cloudStorageId,
    BackupObject backup,
  ) async {
    io.Directory parent = io.Directory("${kSupportDirectory.path}/${FilePathType.backups.name}");

    var file = io.File("${parent.path}/$cloudStorageId.json");
    if (!file.existsSync()) {
      await file.create(recursive: true);
      debugPrint('BackupFileConstructor#constructFile createdFile: ${file.path.replaceAll(' ', '%20')}');
    }

    debugPrint('BackupFileConstructor#constructFile encodingJson');
    String encodedJson = jsonEncode(backup.toContents());
    debugPrint('BackupFileConstructor#constructFile encodedJson');

    if (backup.fileInfo.hasCompression == true) {
      final compressed = GzipService.compress(encodedJson);
      return file.writeAsBytes(compressed);
    }

    return file.writeAsString(encodedJson);
  }
}
