import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';

class BackupProvider extends ChangeNotifier {
  BackupProvider() {
    recheckAndSync();

    step1MessageStream.listen((message) {
      step1Message = message;
      notifyListeners();
    });

    step2MessageStream.listen((message) {
      step2Message = message;
      notifyListeners();
    });

    step3MessageStream.listen((message) {
      step3Message = message;
      notifyListeners();
    });

    step4MessageStream.listen((message) {
      step4Message = message;
      notifyListeners();
    });

    for (var database in BackupRepository.databases) {
      database.addGlobalListener(_databaseListener);
    }
  }

  Future<void> _databaseListener() async {
    _lastDbUpdatedAt = await repository.getLastDbUpdatedAt();
    notifyListeners();
  }

  BackupRepository get repository => BackupRepository.appInstance;

  GoogleUserObject? get currentUser => repository.currentUser;
  bool get isSignedIn => repository.isSignedIn;

  Stream<BackupSyncMessage?> get step1MessageStream => repository.step1ImagesUploader.message;
  Stream<BackupSyncMessage?> get step2MessageStream => repository.step2LatestBackupChecker.message;
  Stream<BackupSyncMessage?> get step3MessageStream => repository.step3LatestBackupImporter.message;
  Stream<BackupSyncMessage?> get step4MessageStream => repository.step4NewBackupUploader.message;

  BackupSyncMessage? step1Message;
  BackupSyncMessage? step2Message;
  BackupSyncMessage? step3Message;
  BackupSyncMessage? step4Message;

  BackupConnectionStatus? _connectionStatus;
  BackupConnectionStatus? get connectionStatus => _connectionStatus;

  bool get synced => lastSyncedAt != null && lastSyncedAt == lastDbUpdatedAt;
  bool get readyToSynced => _connectionStatus == BackupConnectionStatus.readyToSync && currentUser?.email != null;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  DateTime? _lastDbUpdatedAt;
  DateTime? get lastDbUpdatedAt => _lastDbUpdatedAt;

  bool _syncing = false;
  bool get syncing => _syncing;

  Future<void> recheckAndSync() async {
    _syncing = true;
    repository.resetMessages();
    notifyListeners();

    _connectionStatus = await repository.checkConnection();
    notifyListeners();

    if (readyToSynced) {
      await runZonedGuarded(() async {
        await _syncBackupAcrossDevices(currentUser!.email).timeout(const Duration(minutes: 3));
      }, (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, reason: 'Uncaught in zone');
      });
    }

    _syncing = false;
    notifyListeners();
  }

  Future<void> signIn(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#signIn',
      future: () => repository.signIn(),
    );

    if (context.mounted) context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
    AnalyticsService.instance.logSignInWithGoogle();

    _connectionStatus = BackupConnectionStatus.readyToSync;
    _lastSyncedAt = null;
    _lastDbUpdatedAt = null;

    notifyListeners();
  }

  Future<void> requestScope(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#requestScope',
      future: () => repository.requestScope(),
    );

    AnalyticsService.instance.logRequestGoogleDriveScope();
    notifyListeners();
    await recheckAndSync();
  }

  Future<void> signOut(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#signOut',
      future: () => repository.signOut(),
    );

    AnalyticsService.instance.logSignOut();

    _connectionStatus = null;
    _lastSyncedAt = null;
    _lastDbUpdatedAt = null;

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
  Future<void> _syncBackupAcrossDevices(String email) async {
    _lastDbUpdatedAt = await repository.getLastDbUpdatedAt();
    notifyListeners();

    bool step1Success = await repository.startStep1();
    if (!step1Success) {
      _connectionStatus = await repository.checkConnection();
      notifyListeners();
      return;
    }

    final step2Response = await repository.startStep2(_lastDbUpdatedAt);
    _lastSyncedAt = step2Response.lastSyncedAt;
    notifyListeners();

    if (step2Response.hasError) {
      _connectionStatus = await repository.checkConnection();
      notifyListeners();
      return;
    }

    bool step3Success = await repository.startStep3(step2Response.backupContent, _lastSyncedAt, _lastDbUpdatedAt);
    if (!step3Success) return;

    _lastDbUpdatedAt = await repository.getLastDbUpdatedAt();
    notifyListeners();

    final backupUploaderResponse = await repository.startStep4(_lastSyncedAt, _lastDbUpdatedAt);
    if (backupUploaderResponse.hasError) return;

    // once all success, mark both equal to indicate that they are synced.
    _lastDbUpdatedAt = await repository.getLastDbUpdatedAt();
    _lastSyncedAt = backupUploaderResponse.uploadedCloudFile?.getFileInfo()?.createdAt ?? _lastDbUpdatedAt;
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
