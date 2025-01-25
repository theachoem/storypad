import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/concerns/schedule_concern.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';
import 'package:storypad/core/services/backup_sources/google_drive_backup_source.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/restore_backup_service.dart';
import 'package:storypad/views/home/home_view_model.dart';

class BackupProvider extends ChangeNotifier with ScheduleConcern {
  final BaseBackupSource source = GoogleDriveBackupSource();

  DateTime? _lastDbUpdatedAt;
  DateTime? get lastDbUpdatedAt => _lastDbUpdatedAt;
  DateTime? get lastSyncedAt => source.lastSyncedAt;

  int? _storyCount;
  bool get storyEmpty => _storyCount == 0;

  bool _syncing = false;
  bool get syncing => _syncing;
  bool get synced => lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt;

  void setSyncing(bool value) {
    _syncing = value;
    notifyListeners();
  }

  bool canBackup() => !storyEmpty && _lastDbUpdatedAt != null && _lastDbUpdatedAt != source.lastSyncedAt;

  void _databaseListener() async {
    debugPrint('BackupProvider#_databaseListener');
    _lastDbUpdatedAt = await _getLastDbUpdatedAt();
    _storyCount = await StoryDbModel.db.count();
    notifyListeners();
  }

  BackupProvider() {
    for (var database in BaseBackupSource.databases) {
      database.addGlobalListener(_databaseListener);
    }
    load();
  }

  Future<void> load() async {
    _lastDbUpdatedAt = await _getLastDbUpdatedAt();
    _storyCount = await StoryDbModel.db.count();

    await source.authenticate();
    await source.loadLatestBackup();

    notifyListeners();
  }

  // Synchronization flow for multiple devices:
  //
  // 1. Device A writes a new story at 12 PM and backs up the data to google drive.
  // 2. Device B writes a new story at 3 PM. Before backing up, it retrieves the latest backup from 12 PM.
  //    - It compares each document from the backup with the local data.
  //    - If a document from the backup has a newer `updatedAt` timestamp than the local version, the backup data is applied.
  // 3. Device A opens the app again and retrieves the latest data from 3 PM.
  //    - It repeats the comparison process and updates the local data if the retrieved data is newer.
  //
  Future<void> syncBackupAcrossDevices() async {
    if (syncing) return;

    AnalyticsService.instance.logSyncBackup();
    setSyncing(true);

    try {
      await _syncBackupAcrossDevices().timeout(const Duration(seconds: 60));
    } catch (e) {
      debugPrint("🐛 $runtimeType#_syncBackupAcrossDevices error: $e");
    }

    setSyncing(false);
  }

  Future<void> _syncBackupAcrossDevices() async {
    await source.loadLatestBackup();

    CloudFileObject? previousSyncedFile = source.syncedFile;
    if (previousSyncedFile != null && source.lastSyncedAt != _lastDbUpdatedAt) {
      setSyncing(true);

      BackupObject? backup = await source.getBackup(source.syncedFile!);
      if (backup != null) {
        debugPrint('🚧 $runtimeType#_syncBackupAcrossDevices -> restoreOnlyNewData');
        await RestoreBackupService.instance.restoreOnlyNewData(backup: backup);
      }
    }

    if (canBackup()) {
      setSyncing(true);

      await source.backup(lastDbUpdatedAt: lastDbUpdatedAt!);
      await source.loadLatestBackup();

      // delete previous backup file if from same device ID.
      if (previousSyncedFile != null &&
          previousSyncedFile.getFileInfo()?.device.id == source.syncedFile?.getFileInfo()?.device.id) {
        queueDeleteBackupByCloudFileId(previousSyncedFile.id);
      }
    }
  }

  Future<DateTime?> _getLastDbUpdatedAt() async {
    DateTime? updatedAt;

    for (var db in BaseBackupSource.databases) {
      DateTime? newUpdatedAt = await db.getLastUpdatedAt();
      if (newUpdatedAt == null) continue;

      if (updatedAt != null) {
        if (newUpdatedAt.isBefore(updatedAt)) continue;
        updatedAt = newUpdatedAt;
      } else {
        updatedAt = newUpdatedAt;
      }
    }

    return updatedAt;
  }

  Future<void> signOut() async {
    await source.signOut();
    await source.loadLatestBackup();

    AnalyticsService.instance.logSignOut();

    notifyListeners();
  }

  Future<void> signIn() async {
    await source.signIn();
    await source.loadLatestBackup();

    AnalyticsService.instance.logSignInWithGoogle();

    notifyListeners();
  }

  Future<void> deleteCloudFile(CloudFileObject file) async {
    await source.deleteCloudFile(file.id);
    await source.loadLatestBackup();

    AnalyticsService.instance.logDeleteCloudFile(cloudFile: file);

    notifyListeners();
  }

  Future<void> recheck() async {
    _lastDbUpdatedAt = await _getLastDbUpdatedAt();
    await source.loadLatestBackup();
    debugPrint('$runtimeType#recheck synced: $synced');
    notifyListeners();
  }

  Future<void> forceRestore(BackupObject backup, BuildContext context) async {
    MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#forceRestore',
      future: () => RestoreBackupService.instance.forceRestore(backup: backup),
    );

    AnalyticsService.instance.logForceRestoreBackup(
      backupFileInfo: backup.fileInfo,
    );

    await context.read<HomeViewModel>().load(debugSource: '$runtimeType#forceRestore');

    if (!context.mounted) return;
    MessengerService.of(context).showSnackBar("Backup is restored!");
  }

  void queueDeleteBackupByCloudFileId(String id) {
    _toDeleteBackupIds.add(id);
    _deletingBackupTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      String? toDeleteId = _toDeleteBackupIds.firstOrNull;
      debugPrint('BackupProvider#deleteHistoryQueue queue timer: $_deletingBackupId');

      if (toDeleteId == null) {
        _deletingBackupTimer?.cancel();
        _deletingBackupTimer = null;
        return;
      }

      if (_deletingBackupId != null) return;
      _deletingBackupId = toDeleteId;
      await source.deleteCloudFile(toDeleteId);

      _deletingBackupId = null;
      if (_toDeleteBackupIds.contains(toDeleteId)) _toDeleteBackupIds.remove(toDeleteId);
    });
  }

  final Set<String> _toDeleteBackupIds = {};
  Timer? _deletingBackupTimer;
  String? _deletingBackupId;
}
