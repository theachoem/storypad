import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/gzip_service.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/types/file_path_type.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

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

      return await _start(client, lastDbUpdatedAt);
    } on exp.AuthException catch (e) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: e.userFriendlyMessage,
      ));
      rethrow; // Let repository handle auth exceptions
    } on exp.BackupException catch (e) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: e.userFriendlyMessage,
      ));
      return BackupUploaderResponse(
        hasError: true,
        uploadedCloudFile: null,
      );
    } catch (error, stackTrace) {
      debugPrint('$runtimeType#start unexpected error: $error $stackTrace');
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Failed to upload new stories due to unexpected error.',
      ));

      return BackupUploaderResponse(
        hasError: true,
        uploadedCloudFile: null,
      );
    }
  }

  Future<BackupUploaderResponse> _start(GoogleDriveClient client, DateTime lastDbUpdatedAt) async {
    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    try {
      final backup = await BackupDatabasesToBackupObjectService.call(
        databases: BackupRepository.databases,
        lastUpdatedAt: lastDbUpdatedAt,
      );

      final file = await constructBackupFile(
        AssetDbModel.cloudId,
        backup,
      );

      final uploadedFile = await RetryExecutor.execute(
        () => client.uploadFile(
          backup.fileInfo.fileNameWithExtention,
          file,
        ),
        policy: RetryPolicy.network,
        operationName: 'upload_backup_${backup.fileInfo.fileNameWithExtention}',
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

      throw exp.FileOperationException(
        'Upload completed but no file object returned',
        exp.FileOperationType.upload,
        context: backup.fileInfo.fileNameWithExtention,
      );
    } catch (e) {
      if (e is exp.BackupException) rethrow;

      throw exp.ServiceException(
        'Backup upload failed: $e',
        exp.ServiceExceptionType.unexpectedError,
        context: 'backup_upload',
      );
    }
  }

  Future<io.File> constructBackupFile(
    String cloudStorageId,
    BackupObject backup,
  ) async {
    try {
      final parent = io.Directory("${kSupportDirectory.path}/${FilePathType.backups.name}");
      final file = io.File("${parent.path}/$cloudStorageId.json");

      if (!file.existsSync()) {
        await file.create(recursive: true);
        debugPrint('BackupFileConstructor#constructFile createdFile: ${file.path.replaceAll(' ', '%20')}');
      }

      debugPrint('BackupFileConstructor#constructFile encodingJson');
      final encodedJson = jsonEncode(backup.toContents());
      debugPrint('BackupFileConstructor#constructFile encodedJson');

      if (backup.fileInfo.hasCompression == true) {
        try {
          final compressed = GzipService.compress(encodedJson);
          return await file.writeAsBytes(compressed);
        } catch (e) {
          throw exp.ServiceException(
            'Failed to compress backup data: $e',
            exp.ServiceExceptionType.compressionFailed,
            context: cloudStorageId,
          );
        }
      }

      return await file.writeAsString(encodedJson);
    } on io.FileSystemException catch (e) {
      throw exp.ServiceException(
        'Failed to create backup file: $e',
        exp.ServiceExceptionType.unexpectedError,
        context: cloudStorageId,
      );
    } catch (e) {
      if (e is exp.ServiceException) rethrow;

      throw exp.ServiceException(
        'Unexpected error creating backup file: $e',
        exp.ServiceExceptionType.unexpectedError,
        context: cloudStorageId,
      );
    }
  }
}
