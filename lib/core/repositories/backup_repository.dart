import 'dart:async';
import 'dart:io' as io;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backup/backup_syncer_service.dart';
import 'package:storypad/core/services/backup/google_sign_in_service.dart';

enum BackupTileStatus {
  authenticating,
  noInternetToCheck,
  noSignIn,
  errorShouldRetry,
  needRequestAccessScopes,
  uploadingAssets,
  checkingLatestBackupWithCloud,
  restoringLatestBackupFromCloud,
  uploadingBackupFromThisDevice,
  canSync,
  synced;

  bool get syning =>
      this == checkingLatestBackupWithCloud ||
      this == restoringLatestBackupFromCloud ||
      this == uploadingBackupFromThisDevice;
}

class BackupRepository {
  final BackupSyncerService _syncerService;
  final GoogleSignInService _googleSignInService;

  final StreamController<BackupTileStatus> backupTileStatusController = StreamController<BackupTileStatus>.broadcast();

  GoogleUserObject? get currentUser => _googleSignInService.currentUser;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  BackupRepository(
    this._syncerService,
    this._googleSignInService,
  );

  Future<void> initialize() => _load();
  Future<void> retry() => _load();

  Future<void> markAsUnsync() async {
    if (await backupTileStatusController.stream.last == BackupTileStatus.synced) {
      backupTileStatusController.add(BackupTileStatus.canSync);
    }
  }

  Future<void> _load() async {
    backupTileStatusController.add(BackupTileStatus.authenticating);
    final renewResponse = await _googleSignInService.renewToken();

    switch (renewResponse) {
      case GoogleSignInRenewResponse.noInternet:
        backupTileStatusController.add(BackupTileStatus.noInternetToCheck);
        break;
      case GoogleSignInRenewResponse.signInRequired:
        backupTileStatusController.add(BackupTileStatus.noSignIn);
        break;
      case GoogleSignInRenewResponse.failedUnknown:
        backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
        break;
      case GoogleSignInRenewResponse.success:
        await syncFromCloudIfNeeded();
        break;
    }
  }

  Future<void> signIn() async {
    if (await backupTileStatusController.stream.last != BackupTileStatus.noSignIn) return;

    bool signedIn = await _googleSignInService.signIn();
    if (signedIn) {
      await syncFromCloudIfNeeded();
    } else {
      backupTileStatusController.add(BackupTileStatus.noSignIn);
    }
  }

  Future<void> signOut() async {
    await _googleSignInService.signOut();
    backupTileStatusController.add(BackupTileStatus.noSignIn);
  }

  Future<void> requestAccessScopesAndSync() async {
    if (await backupTileStatusController.stream.last != BackupTileStatus.needRequestAccessScopes) return;

    backupTileStatusController.add(BackupTileStatus.authenticating);
    bool success = await _googleSignInService.requestScope();

    if (success) {
      await syncFromCloudIfNeeded();
    } else {
      backupTileStatusController.add(BackupTileStatus.needRequestAccessScopes);
    }
  }

  Future<bool> deleteAsset(AssetDbModel asset, int storyCount) async {
    final uploadedEmails = asset.getGoogleDriveForEmails() ?? [];

    // when image is not yet upload, allow delete locally.
    if (uploadedEmails.isEmpty) {
      await asset.delete();
      return true;
    }

    if (currentUser?.email == null) return false;
    final fileId = asset.getGoogleDriveIdForEmail(currentUser!.email);

    if (fileId != null) {
      final success = await _syncerService.deleteCloudFile(fileId);

      if (success) {
        await asset.delete();
        return true;
      }

      return false;
    } else {
      // Allow delete db asset when no file ID for current email found.
      await asset.delete();
      return true;
    }
  }

  Future<void> syncFromCloudIfNeeded() async {
    try {
      await _syncFromCloudIfNeeded();
    } on io.SocketException {
      backupTileStatusController.add(BackupTileStatus.noInternetToCheck);
    } on drive.DetailedApiRequestError catch (e) {
      final is403 = e.status == 403;
      final is401 = e.status == 401;
      final invalidCredentials = e.message?.contains('Request had invalid authentication credentials') == true;

      if (is403) {
        backupTileStatusController.add(BackupTileStatus.needRequestAccessScopes);
        return;
      }

      if (is401 && invalidCredentials) {
        await _googleSignInService.signOut();
        backupTileStatusController.add(BackupTileStatus.noSignIn);
        return;
      }

      if (is401) {
        await _googleSignInService.renewToken();
        backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
        return;
      }

      backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
    } catch (error) {
      backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
      FirebaseCrashlytics.instance.recordError("$runtimeType#syncFromCloudIfNeeded failed: $error", null);
    }
  }

  Future<void> _syncFromCloudIfNeeded() async {
    if (currentUser == null) {
      backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
      return;
    }

    backupTileStatusController.add(BackupTileStatus.uploadingAssets);
    bool noMoreAssetsToUpload = await _syncerService.uploadAssets(currentUser!.email);
    if (!noMoreAssetsToUpload) {
      backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
      return;
    }

    backupTileStatusController.add(BackupTileStatus.checkingLatestBackupWithCloud);

    bool shouldSyncFromCloud;
    CloudFileObject? lastestCloudFile;
    (shouldSyncFromCloud, lastestCloudFile) = await _syncerService.checkShouldSyncFromCloud();

    if (!shouldSyncFromCloud) {
      _lastSyncedAt = lastestCloudFile?.getFileInfo()?.createdAt;
      backupTileStatusController.add(BackupTileStatus.synced);
      return;
    }

    if (lastestCloudFile != null) {
      backupTileStatusController.add(BackupTileStatus.restoringLatestBackupFromCloud);
      bool restored = await _syncerService.restoreLatestBackupFromCloud(lastestCloudFile);

      if (!restored) {
        backupTileStatusController.add(BackupTileStatus.errorShouldRetry);
        return;
      }
    }

    bool shouldBackup = await _syncerService.checkShouldBackup(lastestCloudFile);
    if (shouldBackup) {
      backupTileStatusController.add(BackupTileStatus.uploadingBackupFromThisDevice);
      await _syncerService.uploadBackupFromThisDevice();
    }

    _lastSyncedAt = lastestCloudFile?.getFileInfo()?.createdAt;
    backupTileStatusController.add(BackupTileStatus.synced);
  }
}
