import 'dart:async';
import 'dart:convert';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';

class BackupLatestCheckerResponse {
  final bool hasError;
  final Map<int, CloudFileObject>? backupCloudFileByYear; // v3: map of year -> CloudFileObject
  final Map<int, BackupObject>? backupContentsByYear; // v3: map of year -> BackupObject

  Map<int, DateTime?>? get lastSyncedAtByYear {
    return backupCloudFileByYear?.map((year, file) => MapEntry(year, file.lastUpdatedAt));
  }

  BackupLatestCheckerResponse({
    required this.hasError,
    this.backupCloudFileByYear,
    this.backupContentsByYear,
  });
}

class BackupLatestCheckerService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<BackupLatestCheckerResponse> start(
    BackupCloudService cloudService,
    BackupImportHistoryStorage importHistoryStorage,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    AppLogger.d('🚧 $runtimeType#start ...');

    try {
      return _start(
        cloudService,
        importHistoryStorage,
        lastDbUpdatedAtByYear,
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
      return BackupLatestCheckerResponse(
        hasError: true,
      );
    } catch (e, stackTrace) {
      AppLogger.d('$runtimeType#start unexpected error: $e $stackTrace');
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
    BackupCloudService cloudService,
    BackupImportHistoryStorage importHistoryStorage,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    if (!cloudService.isSignedIn) {
      throw exp.AuthException(
        'Service ${cloudService.serviceType.displayName} is not signed in',
        exp.AuthExceptionType.signInRequired,
        serviceType: cloudService.serviceType,
      );
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    // Fetch yearly backups from this service
    final Map<int, CloudFileObject> backupCloudFileByYear = {};
    final Map<int, BackupObject> backupContentsByYear = {};

    // Fetch all yearly backups from this service
    final remoteYearlyBackupFiles = await RetryExecutor.execute(
      () => cloudService.fetchYearlyBackups(),
      policy: RetryPolicy.network,
      operationName: 'fetch_yearly_backups_${cloudService.serviceType.id}',
    );

    if (remoteYearlyBackupFiles.isEmpty) {
      AppLogger.d('No backups found in ${cloudService.serviceType.displayName}');
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'No backups found',
        ),
      );

      return BackupLatestCheckerResponse(
        hasError: false,
        backupCloudFileByYear: {},
        backupContentsByYear: {},
      );
    }

    backupCloudFileByYear.addAll(remoteYearlyBackupFiles);

    // Determine which years need to be downloaded
    Map<int, CloudFileObject> yearsToDownload = {};
    for (var entry in backupCloudFileByYear.entries) {
      final year = entry.key;
      final remoteFile = entry.value;
      final remoteTimestamp = remoteFile.lastUpdatedAt;
      final localTimestamp = lastDbUpdatedAtByYear?[year];
      AppLogger.d('BackupLatestChecker: Year $year - Remote: $remoteTimestamp, Local: $localTimestamp');

      final importedHistoryDates = await importHistoryStorage.getImportHistoryByYear(cloudService.serviceType, year);
      if (localTimestamp == null || !importedHistoryDates.contains(remoteTimestamp)) {
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
        backupCloudFileByYear: backupCloudFileByYear,
        backupContentsByYear: {},
      );
    }

    // Download and parse backup contents for years that need syncing
    for (var entry in yearsToDownload.entries) {
      final year = entry.key;
      final cloudFile = entry.value;

      AppLogger.d(
        'BackupLatestChecker: Downloading backup for year $year from ${cloudService.serviceType.displayName}',
      );

      final result = await RetryExecutor.execute(
        () => cloudService.getFileContent(cloudFile),
        policy: RetryPolicy.network,
        operationName: 'download_backup_year_$year',
      );

      final fileContent = result?.$1;
      if (fileContent == null) {
        AppLogger.d('BackupLatestChecker: Failed to download year $year');
        continue; // Skip this year, try others
      }

      BackupObject? backupContent;
      try {
        dynamic decodedContents = jsonDecode(fileContent);
        backupContent = BackupObject.fromContents(decodedContents);
        backupContentsByYear[year] = backupContent;
      } catch (e) {
        AppLogger.d('$runtimeType#_start cannot parse backup for year $year: $e');
        // Continue with other years instead of throwing
        continue;
      }
    }

    controller.add(
      BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Found ${backupContentsByYear.length} year(s) to sync',
      ),
    );

    return BackupLatestCheckerResponse(
      hasError: false,
      backupCloudFileByYear: backupCloudFileByYear,
      backupContentsByYear: backupContentsByYear,
    );
  }
}
