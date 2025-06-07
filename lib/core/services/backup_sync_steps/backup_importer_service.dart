import 'dart:async';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/restore_backup_service.dart';

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
    BackupObject? backup,
    DateTime? lastSyncedAt,
    DateTime? lastDbUpdatedAt,
  ) async {
    debugPrint('🚧 $runtimeType#start ...');

    if (lastSyncedAt == null || backup == null || (lastSyncedAt == lastDbUpdatedAt)) {
      controller.add(BackupSyncMessage(processing: false, success: true, message: 'No new data to import.'));
      return true;
    }

    controller.add(BackupSyncMessage(processing: true, success: true, message: null));
    final int changesCount = await restoreService.restoreOnlyNewData(backup: backup);
    controller.add(BackupSyncMessage(
      processing: false,
      success: true,
      message: '$changesCount records are imported or updated.',
    ));

    return true;
  }
}
