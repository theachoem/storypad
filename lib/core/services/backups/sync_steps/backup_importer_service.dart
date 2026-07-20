import 'dart:async';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';

class BackupImporterService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();

  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<bool> start(
    RestoreBackupService restoreService,
    BackupCloudService cloudService,
    BackupImportHistoryStorage importHistoryStorage,
    Map<int, BackupObject>? backupContentsByYear,
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    AppLogger.d('🚧 $runtimeType#start ...');

    if (backupContentsByYear == null || backupContentsByYear.isEmpty) {
      AppLogger.d('$runtimeType#start completed: No backup contents to import.');
      controller.add(BackupSyncMessage(processing: false, success: true, message: 'No new data to import.'));
      return true;
    }

    controller.add(BackupSyncMessage(processing: true, success: true, message: null));

    int totalChangesCount = 0;
    for (var entry in backupContentsByYear.entries) {
      final year = entry.key;
      final backup = entry.value;

      AppLogger.d('BackupImporter: Importing year $year');
      // Hold listeners until every year is in. Ordering (e.g. tag index) spans years,
      // so rebuilding between files would expose a partially merged database.
      final int changesCount = await restoreService.restoreOnlyNewData(backup: backup, notifyCallbacks: false);
      await importHistoryStorage.markAsImported(cloudService.serviceType, year, backup.fileInfo.createdAt);
      totalChangesCount += changesCount;
    }

    await restoreService.notify();

    controller.add(
      BackupSyncMessage(
        processing: false,
        success: true,
        message: '$totalChangesCount records are imported or updated.',
      ),
    );

    return true;
  }
}
