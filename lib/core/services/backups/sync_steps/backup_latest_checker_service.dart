import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

class BackupLatestCheckerResponse {
  final bool hasError;
  final Map<int, CloudFileObject>? yearlyBackupFiles; // v3: map of year -> CloudFileObject
  final Map<int, BackupObject>? yearlyBackupContents; // v3: map of year -> BackupObject

  Map<int, DateTime?>? get lastSyncedAtByYear {
    return yearlyBackupFiles?.map((year, file) => MapEntry(year, file.lastUpdatedAt));
  }

  BackupLatestCheckerResponse({
    required this.hasError,
    this.yearlyBackupFiles,
    this.yearlyBackupContents,
  });
}

class BackupLatestCheckerService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<BackupLatestCheckerResponse> start(
    List<BackupCloudService> services,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    debugPrint('🚧 $runtimeType#start ...');

    try {
      return await _start(services, lastDbUpdatedAtByYear);
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
      return BackupLatestCheckerResponse(
        hasError: true,
      );
    } catch (e, stackTrace) {
      debugPrint('$runtimeType#start unexpected error: $e $stackTrace');
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: 'Failed to check backup due to unexpected error.',
        ),
      );
      return BackupLatestCheckerResponse(
        hasError: true,
      );
    }
  }

  Future<BackupLatestCheckerResponse> _start(
    List<BackupCloudService> services,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    if (services.isEmpty) {
      throw const exp.AuthException(
        'No backup services available for checking backups',
        exp.AuthExceptionType.signInRequired,
        serviceType: null,
      );
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    // Aggregate yearly backups from all services
    final Map<int, CloudFileObject> allYearlyBackupFiles = {};
    final Map<int, BackupObject> allYearlyBackupContents = {};

    for (final service in services) {
      if (!service.isSignedIn) {
        debugPrint('Skipping service ${service.serviceType.displayName}: not signed in');
        continue;
      }

      // Fetch all yearly backups from this service
      final yearlyBackupFiles = await RetryExecutor.execute(
        () => service.fetchYearlyBackups(),
        policy: RetryPolicy.network,
        operationName: 'fetch_yearly_backups_${service.serviceType.id}',
      );

      if (yearlyBackupFiles.isEmpty) {
        debugPrint('No backups found in ${service.serviceType.displayName}');
        continue;
      }

      // Merge into aggregate map (newer files win)
      for (var entry in yearlyBackupFiles.entries) {
        final year = entry.key;
        final remoteFile = entry.value;
        final existing = allYearlyBackupFiles[year];

        // Keep the newer file
        if (existing == null ||
            (remoteFile.lastUpdatedAt != null &&
                (existing.lastUpdatedAt == null || remoteFile.lastUpdatedAt!.isAfter(existing.lastUpdatedAt!)))) {
          allYearlyBackupFiles[year] = remoteFile;
        }
      }
    }

    if (allYearlyBackupFiles.isEmpty) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'No backups found',
        ),
      );

      return BackupLatestCheckerResponse(
        hasError: false,
        yearlyBackupFiles: {},
        yearlyBackupContents: {},
      );
    }

    // Determine which years need to be downloaded
    Map<int, CloudFileObject> yearsToDownload = {};

    for (var entry in allYearlyBackupFiles.entries) {
      final year = entry.key;
      final remoteFile = entry.value;
      final remoteTimestamp = remoteFile.lastUpdatedAt;
      final localTimestamp = lastDbUpdatedAtByYear?[year];

      debugPrint('BackupLatestChecker: Year $year - Remote: $remoteTimestamp, Local: $localTimestamp');

      // Download if:
      // 1. We have no local data for this year, OR
      // 2. Remote timestamp is newer than local timestamp
      if (localTimestamp == null || (remoteTimestamp != null && remoteTimestamp.isAfter(localTimestamp))) {
        yearsToDownload[year] = remoteFile;
      }
    }

    if (yearsToDownload.isEmpty) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'Everything is up to date',
        ),
      );

      return BackupLatestCheckerResponse(
        hasError: false,
        yearlyBackupFiles: allYearlyBackupFiles,
        yearlyBackupContents: {},
      );
    }

    // Download and parse backup contents for years that need syncing
    for (var entry in yearsToDownload.entries) {
      final year = entry.key;
      final cloudFile = entry.value;

      debugPrint('BackupLatestChecker: Downloading backup for year $year');

      // Find the service that has this file and download from it
      BackupCloudService? targetService;
      for (final service in services) {
        if (!service.isSignedIn) continue;
        final serviceBackups = await RetryExecutor.execute(
          () => service.fetchYearlyBackups(),
          policy: RetryPolicy.network,
          operationName: 'check_service_backups_${service.serviceType.id}',
        );
        if (serviceBackups.containsKey(year)) {
          targetService = service;
          break;
        }
      }

      if (targetService == null) {
        debugPrint('BackupLatestChecker: No service has backup for year $year');
        continue;
      }

      final result = await RetryExecutor.execute(
        () => targetService!.getFileContent(cloudFile),
        policy: RetryPolicy.network,
        operationName: 'download_backup_year_$year',
      );
      final fileContent = result?.$1;

      if (fileContent == null) {
        debugPrint('BackupLatestChecker: Failed to download year $year');
        continue; // Skip this year, try others
      }

      BackupObject? backupContent;
      try {
        dynamic decodedContents = jsonDecode(fileContent);
        backupContent = BackupObject.fromContents(decodedContents);
        allYearlyBackupContents[year] = backupContent;
      } catch (e) {
        debugPrint('$runtimeType#_start cannot parse backup for year $year: $e');
        // Continue with other years instead of throwing
        continue;
      }
    }

    controller.add(
      BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Found ${allYearlyBackupContents.length} year(s) to sync',
      ),
    );

    return BackupLatestCheckerResponse(
      hasError: false,
      yearlyBackupFiles: allYearlyBackupFiles,
      yearlyBackupContents: allYearlyBackupContents,
    );
  }
}
