import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
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
    List<BackupCloudService> services,
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
        services,
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
      debugPrint('$runtimeType#start unexpected error: $e $stackTrace');
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
    List<BackupCloudService> services,
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
    Map<int, CloudFileObject>? existingYearlyBackups,
  ) async {
    if (services.isEmpty) {
      throw const exp.AuthException(
        'No backup services available for uploading backups',
        exp.AuthExceptionType.signInRequired,
        serviceType: null,
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
        uploadedYearlyFiles: existingYearlyBackups,
      );
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    try {
      Map<int, CloudFileObject> uploadedYearlyFiles = {};

      // Upload to all services
      for (final service in services) {
        if (!service.isSignedIn) {
          debugPrint('Skipping service ${service.serviceType.displayName}: not signed in');
          continue;
        }

        for (var entry in yearsToUpload.entries) {
          final year = entry.key;
          final lastUpdatedAt = entry.value;

          debugPrint('BackupUploader: Uploading year $year to ${service.serviceType.displayName}');

          // Generate backup for this year only
          final backup = await BackupDatabasesToBackupObjectService.call(
            databases: BackupRepository.databases,
            lastUpdatedAt: lastUpdatedAt,
            year: year, // Filter by year
          );

          final file = await constructBackupFile(
            service.serviceType,
            year,
            backup,
          );

          CloudFileObject? uploadedFile;
          final existingFile = existingYearlyBackups?[year];

          if (existingFile != null) {
            // Update existing file atomically
            uploadedFile = await RetryExecutor.execute(
              () => service.updateYearlyBackup(
                fileId: existingFile.id,
                fileName: backup.fileInfo.fileNameWithExtention,
                file: file,
              ),
              policy: RetryPolicy.network,
              operationName: 'update_backup_year_${year}_${service.serviceType.id}',
            );
          } else {
            // Upload new file
            uploadedFile = await RetryExecutor.execute(
              () => service.uploadYearlyBackup(
                fileName: backup.fileInfo.fileNameWithExtention,
                file: file,
              ),
              policy: RetryPolicy.network,
              operationName: 'upload_backup_year_${year}_${service.serviceType.id}',
            );
          }

          if (uploadedFile != null) {
            uploadedYearlyFiles[year] = uploadedFile;
          } else {
            debugPrint('BackupUploader: Failed to upload year $year to ${service.serviceType.displayName}');
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
          message: 'Uploaded ${uploadedYearlyFiles.length} year(s) successfully across ${services.length} service(s).',
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
