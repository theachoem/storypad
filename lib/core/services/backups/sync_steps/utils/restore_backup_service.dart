import 'dart:async';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/json_tables_to_model_service.dart';
import 'package:storypad/core/objects/backup_object.dart';

class RestoreBackupService {
  final List<FutureOr<void> Function()> _listeners = [];

  void addListener(
    Future<void> Function() callback,
  ) {
    _listeners.add(callback);
  }

  void removeListener(Future<void> Function() callback) {
    _listeners.remove(callback);
  }

  Future<int> restoreOnlyNewData({
    required BackupObject backup,
  }) async {
    Map<String, dynamic> tables = backup.tables;
    Map<String, List<BaseDbModel>> datas = JsonTablesToModelService.decode(tables);

    int changesCount = 0;

    for (BaseDbAdapter db in BackupRepository.databases) {
      List<BaseDbModel>? items = datas[db.tableName];

      if (items != null) {
        for (BaseDbModel newRecord in items) {
          BaseDbModel? existingRecord = await db.find(newRecord.id, returnDeleted: true);

          if (existingRecord != null && existingRecord.updatedAt != null && newRecord.updatedAt != null) {
            bool backupHasNewerContent = existingRecord.updatedAt!.isBefore(newRecord.updatedAt!);
            bool deviceHasNewerContent = existingRecord.updatedAt!.isAfter(newRecord.updatedAt!);

            if (backupHasNewerContent) {
              await db.set(newRecord, runCallbacks: false);
              changesCount++;
            } else if (deviceHasNewerContent) {
              // Update `updatedAt` to mark the record as unsynced, ensuring the backup provider picks it up later.
              // This prevents the app from incorrectly assuming the database is fully synced after restoration.
              await db.touch(existingRecord, runCallbacks: false);
            } else {
              // this case, contents may be deleted & unchanged on other device.
              // so we can ignore them.
            }
          } else {
            await db.set(newRecord, runCallbacks: false);
            changesCount++;
          }
        }
      }
    }

    await _triggerCallback();
    return changesCount;
  }

  Future<void> forceRestore({
    required BackupObject backup,
  }) async {
    Map<String, dynamic> tables = backup.tables;
    Map<String, List<BaseDbModel>> datas = JsonTablesToModelService.decode(tables);

    for (BaseDbAdapter db in BackupRepository.databases) {
      List<BaseDbModel>? items = datas[db.tableName];
      if (items != null) {
        for (BaseDbModel item in items) {
          await db.set(item, runCallbacks: false);
        }
      }
    }

    await _triggerCallback();
  }

  Future<void> _triggerCallback() async {
    for (FutureOr<void> Function() callback in _listeners) {
      await callback();
    }
  }
}
