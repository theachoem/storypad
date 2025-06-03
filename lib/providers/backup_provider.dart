import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backup/backup_syncer_service.dart';
import 'package:storypad/core/services/backup/google_drive_client_service.dart';
import 'package:storypad/core/services/backup/google_sign_in_service.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';

class BackupProvider extends ChangeNotifier with DebounchedCallback, WidgetsBindingObserver {
  BackupProvider() {
    _backupRepository.initialize();

    for (var database in BaseBackupSource.databases) {
      database.addGlobalListener(() => _backupRepository.markAsUnsync());
    }

    WidgetsBinding.instance.addObserver(this);
    _backupRepository.backupTileStatusController.stream.listen((status) {
      _backupStatus = status;
      notifyListeners();
    });
  }

  final BackupRepository _backupRepository = BackupRepository(
    BackupSyncerService(GoogleDriveClientService()),
    GoogleSignInService(),
  );

  BackupTileStatus? _backupStatus;
  BackupTileStatus? get backupStatus => _backupStatus;
  GoogleUserObject? get currentUser => _backupRepository.currentUser;
  DateTime? get lastSyncedAt => _backupRepository.lastSyncedAt;

  ValueNotifier<int?> uploadingAssetIdNotifier = ValueNotifier(null);

  Future<void> signIn() async => _backupRepository.signIn();
  Future<void> signOut() async => _backupRepository.signOut();
  Future<void> retry() async => _backupRepository.retry();
  Future<void> requestAccessScopesAndSync() async => _backupRepository.requestAccessScopesAndSync();

  Future<void> deleteAsset(AssetDbModel asset, int storyCount) async {
    uploadingAssetIdNotifier.value = asset.id;
    await _backupRepository.deleteAsset(asset, storyCount);
    uploadingAssetIdNotifier.value = null;
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
  Future<void> syncFromCloudIfNeeded() async => _backupRepository.syncFromCloudIfNeeded();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        syncFromCloudIfNeeded();
        break;
    }
  }

  @override
  void dispose() {
    _backupRepository.backupTileStatusController.close();
    uploadingAssetIdNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
