import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/google_drive_client.dart';
import 'package:storypad/core/services/gzip_service.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/types/file_path_type.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

class BackupUploaderResponse {
  final bool hasError;
  final Map<int, CloudFileObject>? uploadedYearlyFiles;

  BackupUploaderResponse({
    required this.hasError,
    this.uploadedYearlyFiles,
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
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
    Map<int, CloudFileObject>? existingYearlyBackups,
  ) async {
    try {
      if (lastDbUpdatedAtByYear == null || lastDbUpdatedAtByYear.isEmpty) {
        controller.add(
          BackupSyncMessage(
            processing: false,
            success: true,
            message: 'No new stories to upload.',
          ),
        );

        return BackupUploaderResponse(
          hasError: false,
          uploadedYearlyFiles: {},
        );
      }

      // Determine which years need uploading
      Map<int, DateTime> yearsToUpload = {};

      for (var entry in lastDbUpdatedAtByYear.entries) {
        final year = entry.key;
        final localTimestamp = entry.value;
        final remoteTimestamp = lastSyncedAtByYear?[year];

        if (localTimestamp == null) continue;

        // Upload if:
        // 1. No remote backup exists for this year, OR
        // 2. Local timestamp is newer than remote timestamp
        if (remoteTimestamp == null || localTimestamp.isAfter(remoteTimestamp)) {
          yearsToUpload[year] = localTimestamp;
        }
      }

      if (yearsToUpload.isEmpty) {
        controller.add(
          BackupSyncMessage(
            processing: false,
            success: true,
            message: 'No new stories to upload.',
          ),
        );

        return BackupUploaderResponse(
          hasError: false,
          uploadedYearlyFiles: existingYearlyBackups,
        );
      }

      return await _start(client, yearsToUpload, existingYearlyBackups ?? {});
    } on exp.AuthException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      rethrow; // Let repository handle auth exceptions
    } on exp.BackupException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      return BackupUploaderResponse(
        hasError: true,
      );
    } catch (error, stackTrace) {
      debugPrint('$runtimeType#start unexpected error: $error $stackTrace');
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: 'Failed to upload new stories due to unexpected error.',
        ),
      );

      return BackupUploaderResponse(
        hasError: true,
      );
    }
  }

  Future<BackupUploaderResponse> _start(
    GoogleDriveClient client,
    Map<int, DateTime> yearsToUpload,
    Map<int, CloudFileObject> existingBackups,
  ) async {
    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    try {
      Map<int, CloudFileObject> uploadedYearlyFiles = {};

      for (var entry in yearsToUpload.entries) {
        final year = entry.key;
        final lastUpdatedAt = entry.value;

        debugPrint('BackupUploader: Uploading year $year');

        // Generate backup for this year only
        final backup = await BackupDatabasesToBackupObjectService.call(
          databases: BackupRepository.databases,
          lastUpdatedAt: lastUpdatedAt,
          year: year, // Filter by year
        );

        final file = await constructBackupFile(
          'year_$year',
          backup,
        );

        CloudFileObject? uploadedFile;
        final existingFile = existingBackups[year];

        if (existingFile != null) {
          // Update existing file atomically
          uploadedFile = await RetryExecutor.execute(
            () => client.updateYearlyBackup(
              fileId: existingFile.id,
              fileName: backup.fileInfo.fileNameWithExtention,
              file: file,
            ),
            policy: RetryPolicy.network,
            operationName: 'update_backup_year_$year',
          );
        } else {
          // Upload new file
          uploadedFile = await RetryExecutor.execute(
            () => client.uploadYearlyBackup(
              fileName: backup.fileInfo.fileNameWithExtention,
              file: file,
            ),
            policy: RetryPolicy.network,
            operationName: 'upload_backup_year_$year',
          );
        }

        if (uploadedFile != null) {
          uploadedYearlyFiles[year] = uploadedFile;
        } else {
          debugPrint('BackupUploader: Failed to upload year $year');
        }
      }

      if (uploadedYearlyFiles.isEmpty) {
        throw const exp.ServiceException(
          'Failed to upload any yearly backups',
          exp.ServiceExceptionType.unexpectedError,
          context: 'backup_upload',
        );
      }

      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'Uploaded ${uploadedYearlyFiles.length} year(s) successfully.',
        ),
      );

      return BackupUploaderResponse(
        hasError: false,
        uploadedYearlyFiles: uploadedYearlyFiles,
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
