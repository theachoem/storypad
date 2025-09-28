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
import 'package:storypad/core/types/backup_result.dart';
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

    final connectionResult = await repository.checkConnection();
    _connectionStatus = connectionResult.data;
    notifyListeners();

    if (connectionResult.error != null) {
      debugPrint('Connection check failed: ${connectionResult.error!.message}');
    }

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
    final result = await MessengerService.of(context).showLoading<BackupResult<bool>>(
      debugSource: '$runtimeType#signIn',
      future: () => repository.signIn(),
    );

    if (result?.isSuccess == true) {
      if (context.mounted) context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
      AnalyticsService.instance.logSignInWithGoogle();

      _connectionStatus = BackupConnectionStatus.readyToSync;
      _lastSyncedAt = null;
      _lastDbUpdatedAt = null;
    } else if (result?.error != null) {
      // Handle sign-in error - could show user-friendly message
      debugPrint('Sign-in failed: ${result!.error!.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!.message)),
        );
      }
    }

    notifyListeners();
  }

  Future<void> requestScope(BuildContext context) async {
    final result = await MessengerService.of(context).showLoading<BackupResult<bool>>(
      debugSource: '$runtimeType#requestScope',
      future: () => repository.requestScope(),
    );

    if (result?.isSuccess == true) {
      AnalyticsService.instance.logRequestGoogleDriveScope();
    } else if (result?.error != null) {
      debugPrint('Request scope failed: ${result!.error!.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!.message)),
        );
      }
    }

    notifyListeners();
    await recheckAndSync();
  }

  Future<void> signOut(BuildContext context) async {
    final result = await MessengerService.of(context).showLoading<BackupResult<void>>(
      debugSource: '$runtimeType#signOut',
      future: () => repository.signOut(),
    );

    // Always update UI state even if sign-out had issues
    if (context.mounted) context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
    AnalyticsService.instance.logSignOut();

    _connectionStatus = null;
    _lastSyncedAt = null;
    _lastDbUpdatedAt = null;

    if (result?.error != null) {
      debugPrint('Sign-out had issues: ${result!.error!.message}');
    }

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

    // Step 1: Upload images
    final step1Result = await repository.startStep1();
    if (!step1Result.isSuccess) {
      if (step1Result.error?.type == BackupErrorType.authentication) {
        final connectionResult = await repository.checkConnection();
        _connectionStatus = connectionResult.data;
      }
      notifyListeners();
      return;
    }

    // Step 2: Check latest backup
    final step2Result = await repository.startStep2(_lastDbUpdatedAt);
    if (step2Result.isSuccess && step2Result.data != null) {
      _lastSyncedAt = step2Result.data!.lastSyncedAt;
    }
    notifyListeners();

    if (!step2Result.isSuccess) {
      if (step2Result.error?.type == BackupErrorType.authentication) {
        final connectionResult = await repository.checkConnection();
        _connectionStatus = connectionResult.data;
      }
      notifyListeners();
      return;
    }

    // Step 3: Import backup if needed
    final step3Result = await repository.startStep3(step2Result.data?.backupContent, _lastSyncedAt, _lastDbUpdatedAt);
    if (!step3Result.isSuccess) return;

    _lastDbUpdatedAt = await repository.getLastDbUpdatedAt();
    notifyListeners();

    // Step 4: Upload new backup
    final step4Result = await repository.startStep4(_lastSyncedAt, _lastDbUpdatedAt);
    if (!step4Result.isSuccess) {
      if (step4Result.error?.type == BackupErrorType.authentication) {
        final connectionResult = await repository.checkConnection();
        _connectionStatus = connectionResult.data;
        notifyListeners();
      }
      return;
    }

    // once all success, mark both equal to indicate that they are synced.
    _lastDbUpdatedAt = await repository.getLastDbUpdatedAt();
    _lastSyncedAt = step4Result.data?.uploadedCloudFile?.getFileInfo()?.createdAt ?? _lastDbUpdatedAt;
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
