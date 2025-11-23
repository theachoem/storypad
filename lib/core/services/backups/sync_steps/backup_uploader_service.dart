import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/gzip_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';
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

  Future<BackupUploaderResponse> startStep4(
    BackupCloudService service,
    BackupImportHistoryStorage importHistoryStorage,
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

      return await _start(
        service,
        importHistoryStorage,
        lastSyncedAtByYear,
        lastDbUpdatedAtByYear,
        existingYearlyBackups,
      );
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
      return BackupUploaderResponse(hasError: true);
    } catch (e, stackTrace) {
      AppLogger.d('$runtimeType#start unexpected error: $e $stackTrace');
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: 'Failed to upload backup due to unexpected error.',
        ),
      );
      return BackupUploaderResponse(hasError: true);
    }
  }

  Future<BackupUploaderResponse> _start(
    BackupCloudService cloudService,
    BackupImportHistoryStorage importHistoryStorage,
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
    Map<int, CloudFileObject>? existingYearlyBackups,
  ) async {
    if (!cloudService.isSignedIn) {
      throw exp.AuthException(
        'Service ${cloudService.serviceType.displayName} is not signed in',
        exp.AuthExceptionType.signInRequired,
        serviceType: cloudService.serviceType,
      );
    }

    // Determine which years need uploading
    Map<int, DateTime> yearsToUpload = {};
    for (var entry in lastDbUpdatedAtByYear!.entries) {
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
        uploadedYearlyFiles: {},
      );
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    try {
      Map<int, CloudFileObject> uploadedYearlyFiles = {};

      for (var entry in yearsToUpload.entries) {
        final year = entry.key;
        final lastUpdatedAt = entry.value;

        AppLogger.d('BackupUploader: Uploading year $year to ${cloudService.serviceType.displayName}');

        // Generate backup for this year only
        final backup = await BackupDatabasesToBackupObjectService.call(
          databases: BackupRepository.databases,
          lastUpdatedAt: lastUpdatedAt,
          year: year, // Filter by year
        );

        final file = await constructBackupFile(
          cloudService.serviceType,
          year,
          backup,
        );

        CloudFileObject? uploadedFile;

        // Get existing backups for this service (fetched during Step 2)
        final existingFile = existingYearlyBackups?[year];

        // Update existing file atomically
        if (existingFile != null) {
          uploadedFile = await RetryExecutor.execute(
            () => cloudService.updateYearlyBackup(
              fileId: existingFile.id,
              fileName: backup.fileInfo.fileNameWithExtention,
              file: file,
            ),
            policy: RetryPolicy.network,
            operationName: 'update_backup_year_${year}_${cloudService.serviceType.id}',
          );
        } else {
          uploadedFile = await RetryExecutor.execute(
            () => cloudService.uploadYearlyBackup(fileName: backup.fileInfo.fileNameWithExtention, file: file),
            policy: RetryPolicy.network,
            operationName: 'upload_backup_year_${year}_${cloudService.serviceType.id}',
          );
        }

        if (uploadedFile != null) {
          uploadedYearlyFiles[year] = uploadedFile;
        } else {
          AppLogger.d('BackupUploader: Failed to upload year $year to ${cloudService.serviceType.displayName}');
        }
      }

      // Mark this service's uploads as imported
      if (uploadedYearlyFiles.isNotEmpty) {
        for (final entry in uploadedYearlyFiles.entries) {
          final year = entry.key;
          final file = entry.value;

          if (file.lastUpdatedAt != null) {
            await importHistoryStorage.markAsImported(cloudService.serviceType, year, file.lastUpdatedAt!);
          }
        }
      }

      if (uploadedYearlyFiles.isEmpty) {
        throw const exp.ServiceException(
          'Failed to upload any yearly backups',
          exp.ServiceExceptionType.unexpectedError,
          context: 'backup_upload',
          serviceType: null,
        );
      }

      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message:
              'Uploaded ${uploadedYearlyFiles.length} year(s) successfully to ${cloudService.serviceType.displayName}.',
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
        serviceType: null,
      );
    }
  }

  /// Construct a local backup file from BackupObject
  ///
  /// Creates a temporary file with JSON content (optionally compressed with GZIP).
  /// File is stored in support directory under backups/ folder.
  ///
  /// Returns: File handle to the created backup file
  Future<io.File> constructBackupFile(
    BackupServiceType serviceType,
    int year,
    BackupObject backup,
  ) async {
    try {
      final parent = io.Directory("${kSupportDirectory.path}/${FilePathType.backups.name}");
      final file = io.File("${parent.path}/${serviceType.id}_year_$year.json");

      if (!file.existsSync()) {
        await file.create(recursive: true);
        AppLogger.d('BackupFileConstructor#constructFile createdFile: ${file.path.replaceAll(' ', '%20')}');
      }

      AppLogger.d('BackupFileConstructor#constructFile encodingJson');
      final encodedJson = jsonEncode(backup.toContents());
      AppLogger.d('BackupFileConstructor#constructFile encodedJson');

      if (backup.fileInfo.hasCompression == true) {
        try {
          final compressed = GzipService.compress(encodedJson);
          return await file.writeAsBytes(compressed);
        } catch (e) {
          throw exp.ServiceException(
            'Failed to compress backup data: $e',
            exp.ServiceExceptionType.compressionFailed,
            context: year.toString(),
            serviceType: serviceType,
          );
        }
      }

      return await file.writeAsString(encodedJson);
    } on io.FileSystemException catch (e) {
      throw exp.ServiceException(
        'Failed to create backup file: $e',
        exp.ServiceExceptionType.unexpectedError,
        context: year.toString(),
        serviceType: serviceType,
      );
    } catch (e) {
      if (e is exp.ServiceException) rethrow;

      throw exp.ServiceException(
        'Unexpected error creating backup file: $e',
        exp.ServiceExceptionType.unexpectedError,
        context: year.toString(),
        serviceType: serviceType,
      );
    }
  }
}
