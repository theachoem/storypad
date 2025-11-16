import 'dart:async';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/restore_backup_service.dart';

class BackupImporterService {
  final RestoreBackupService restoreService;
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();

  Stream<BackupSyncMessage?> get message => controller.stream;

  BackupImporterService({
    required this.restoreService,
  });

  void reset() {
    controller.add(null);
  }

  Future<bool> start(
    Map<int, BackupObject>? yearlyBackupContents,
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    debugPrint('🚧 $runtimeType#start ...');

    if (yearlyBackupContents == null || yearlyBackupContents.isEmpty) {
      controller.add(BackupSyncMessage(processing: false, success: true, message: 'No new data to import.'));
      return true;
    }

    // Defensive validation: Check if any year needs importing
    // Note: Step 2 already filtered downloads by timestamp, but we validate again for robustness
    // and to support independent testing of this service
    bool hasChanges = false;
    for (var entry in yearlyBackupContents.entries) {
      final year = entry.key;
      final remoteSyncedAt = lastSyncedAtByYear?[year];
      final localUpdatedAt = lastDbUpdatedAtByYear?[year];

      if (remoteSyncedAt == null || localUpdatedAt == null || remoteSyncedAt.isAfter(localUpdatedAt)) {
        hasChanges = true;
        break;
      }
    }

    if (!hasChanges) {
      controller.add(BackupSyncMessage(processing: false, success: true, message: 'No new data to import.'));
      return true;
    }

    controller.add(BackupSyncMessage(processing: true, success: true, message: null));

    int totalChangesCount = 0;
    for (var entry in yearlyBackupContents.entries) {
      final year = entry.key;
      final backup = entry.value;

      debugPrint('BackupImporter: Importing year $year');
      final int changesCount = await restoreService.restoreOnlyNewData(backup: backup);
      totalChangesCount += changesCount;
    }

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
