import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/asset_backup_service.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';
import 'package:storypad/core/services/backup_sources/google_drive_backup_source.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/queue_delete_backup_service.dart';
import 'package:storypad/core/services/backups/restore_backup_service.dart';
import 'package:storypad/views/home/home_view_model.dart';

class BackupProvider extends ChangeNotifier with DebounchedCallback {
  final BaseBackupSource source = GoogleDriveBackupSource();

  late final AssetBackupService assetBackupState = AssetBackupService(
    notifyListeners: notifyListeners,
    source: source,
  );

  late final QueueDeleteBackupService queueDeleteBackupState = QueueDeleteBackupService(
    source: source,
  );

  DateTime? _lastDbUpdatedAt;
  DateTime? get lastDbUpdatedAt => _lastDbUpdatedAt;

  CloudFileObject? _syncedFile;
  CloudFileObject? get syncedFile => _syncedFile;
  DateTime? get lastSyncedAt => _syncedFile?.getFileInfo()?.createdAt;

  int? _storyCount;
  bool get storyEmpty => _storyCount == 0;

  bool _syncing = false;
  bool get syncing => _syncing;
  bool get synced => lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt;

  void setSyncing(bool value) {
    _syncing = value;
    notifyListeners();
  }

  bool canBackup() => !storyEmpty && _lastDbUpdatedAt != null && _lastDbUpdatedAt != lastSyncedAt;

  Future<void> _databaseListener() async {
    debugPrint('BackupProvider#_databaseListener');
    await _loadLocalData();
    notifyListeners();
  }

  BackupProvider() {
    for (var database in BaseBackupSource.databases) {
      database.addGlobalListener(_databaseListener);
    }

    Future.delayed(Duration(seconds: 1)).then((_) {
      load();
    });
  }

  Future<void> load() async {
    await source.authenticate();
    await _loadLocalData();
    await _loadLatestSyncedFile();

    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    _lastDbUpdatedAt = await _getLastDbUpdatedAt();
    _storyCount = await StoryDbModel.db.count();
    await assetBackupState.loadAssets();
  }

  Future<void> _loadLatestSyncedFile() async {
    if (source.isSignedIn == null) return;
    if (source.isSignedIn == true) {
      _syncedFile = await source.getLastestBackupFile();
    } else {
      _syncedFile = null;
    }
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
  Future<void> syncBackupAcrossDevices(BuildContext context) async {
    if (syncing) return;

    AnalyticsService.instance.logSyncBackup();
    setSyncing(true);

    try {
      await assetBackupState.uploadAssets();
      if (assetBackupState.localAssets != null && assetBackupState.localAssets?.isNotEmpty == true) return;
      await _syncBackupAcrossDevices().timeout(const Duration(seconds: 60));
    } catch (e) {
      debugPrint("🐛 $runtimeType#_syncBackupAcrossDevices error: $e");

      StackTrace? stackTrace;
      if (e is StateError) {
        debugPrintStack(stackTrace: e.stackTrace);
        stackTrace = e.stackTrace;
      }

      FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }

    setSyncing(false);
  }

  Future<void> _syncBackupAcrossDevices() async {
    await _loadLatestSyncedFile();
    notifyListeners();

    final previousSyncedFile = _syncedFile;
    if (previousSyncedFile != null && lastSyncedAt != _lastDbUpdatedAt) {
      BackupObject? backup = await source.getBackup(previousSyncedFile);
      if (backup != null) {
        debugPrint('🚧 $runtimeType#_syncBackupAcrossDevices -> restoreOnlyNewData');
        await RestoreBackupService.instance.restoreOnlyNewData(backup: backup);
        await _loadLocalData();
      }
    }

    if (canBackup()) {
      CloudFileObject? uploadedSyncedFile = await source.backup(lastDbUpdatedAt: lastDbUpdatedAt!);
      if (uploadedSyncedFile == null) return;

      // delete previous backup file if from same device ID.
      bool sameDeviceID = previousSyncedFile != null &&
          previousSyncedFile.getFileInfo()?.device.id == uploadedSyncedFile.getFileInfo()?.device.id;
      if (sameDeviceID) {
        queueDeleteBackupState.delete(previousSyncedFile.id);
      }

      _syncedFile = uploadedSyncedFile;
      notifyListeners();
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

  Future<void> signOut({
    required BuildContext context,
    required String debugSource,
    bool showLoading = false,
  }) async {
    Future<void> _() async {
      await source.signOut();
      await _loadLatestSyncedFile();
      await assetBackupState.loadAssets();
    }

    showLoading
        ? await MessengerService.of(context).showLoading(future: () => _(), debugSource: debugSource)
        : await _();

    AnalyticsService.instance.logSignOut();
    notifyListeners();
  }

  Future<void> signIn({
    required BuildContext context,
    required String debugSource,
    bool showLoading = false,
  }) async {
    Future<void> _() async {
      await source.signIn();
      await _loadLatestSyncedFile();
      await assetBackupState.loadAssets();
    }

    showLoading
        ? await MessengerService.of(context).showLoading(future: () => _(), debugSource: debugSource)
        : await _();

    AnalyticsService.instance.logSignInWithGoogle();
    notifyListeners();
  }

  Future<void> deleteCloudFile(CloudFileObject file) async {
    await source.deleteCloudFile(file.id);
    await _loadLatestSyncedFile();

    AnalyticsService.instance.logDeleteCloudFile(cloudFile: file);
    notifyListeners();
  }

  Future<void> recheck() async {
    await _loadLocalData();
    await _loadLatestSyncedFile();

    debugPrint('$runtimeType#recheck synced: $synced');
    notifyListeners();
  }

  Future<void> forceRestore(BackupObject backup, BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#forceRestore',
      future: () => RestoreBackupService.instance.forceRestore(backup: backup),
    );

    if (!context.mounted) return;
    AnalyticsService.instance.logForceRestoreBackup(backupFileInfo: backup.fileInfo);
    await context.read<HomeViewModel>().reload(debugSource: '$runtimeType#forceRestore');

    if (!context.mounted) return;
    MessengerService.of(context).showSnackBar(tr("snack_bar.force_restore_success"));
  }

  @override
  void dispose() {
    assetBackupState.dispose();
    super.dispose();
  }
}
