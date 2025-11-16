import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
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
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();
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

  DateTime? get lastSyncedAt => _lastSyncedAtByYear?.values.whereType<DateTime>().fold<DateTime?>(
    null,
    (latest, current) => latest == null || current.isAfter(latest) ? current : latest,
  );

  DateTime? get lastDbUpdatedAt => _lastDbUpdatedAtByYear?.values.whereType<DateTime>().fold<DateTime?>(
    null,
    (latest, current) => latest == null || current.isAfter(latest) ? current : latest,
  );

  Map<int, DateTime?>? _lastSyncedAtByYear; // v3: tracks last sync timestamp per year
  Map<int, DateTime?>? get lastSyncedAtByYear => _lastSyncedAtByYear;

  Map<int, DateTime?>? _lastDbUpdatedAtByYear; // v3: tracks last DB update timestamp per year
  Map<int, DateTime?>? get lastDbUpdatedAtByYear => _lastDbUpdatedAtByYear;

  bool _syncing = false;
  bool get syncing => _syncing;

  List<BackupCloudService> get services => repository.services;

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
      await _syncBackupAcrossDevices(currentUser!.email);
    }

    _syncing = false;
    notifyListeners();
  }

  Future<void> signIn(
    BuildContext context,
    BackupServiceType serviceType,
  ) async {
    final result = await MessengerService.of(context).showLoading<BackupResult<bool>>(
      debugSource: '$runtimeType#signIn',
      future: () => repository.signIn(serviceType),
    );

    if (result?.isSuccess == true) {
      if (context.mounted) context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
      AnalyticsService.instance.logSignInWithGoogle();

      _connectionStatus = BackupConnectionStatus.readyToSync;
      _lastSyncedAtByYear = null;
      _lastDbUpdatedAtByYear = null;
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

  Future<void> requestScope(
    BuildContext context,
    BackupServiceType serviceType,
  ) async {
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

  Future<void> signOut(
    BuildContext context,
    BackupServiceType serviceType,
  ) async {
    final result = await MessengerService.of(context).showLoading<BackupResult<void>>(
      debugSource: '$runtimeType#signOut',
      future: () => repository.signOut(serviceType),
    );

    // Always update UI state even if sign-out had issues
    if (context.mounted) context.read<InAppPurchaseProvider>().revalidateCustomerInfo(context);
    AnalyticsService.instance.logSignOut();

    _connectionStatus = null;
    _lastSyncedAtByYear = null;
    _lastDbUpdatedAtByYear = null;

    if (result?.error != null) {
      debugPrint('Sign-out had issues: ${result!.error!.message}');
    }

    notifyListeners();
  }

  // Synchronization flow for multiple devices (v3 yearly backups):
  //
  // 1. Device A writes a new story at 12 PM and backs up the data to google drive (year-specific file).
  // 2. Device B writes a new story at 3 PM. Before backing up, it retrieves the latest backup for that year.
  //    - It compares each document from the backup with the local data.
  //    - If a document from the backup has a newer `updatedAt` timestamp than the local version, the backup data is applied.
  // 3. Device A opens the app again and retrieves the latest data from 3 PM for affected years.
  //    - It repeats the comparison process and updates the local data if the retrieved data is newer.
  //
  Future<void> _syncBackupAcrossDevices(String email) async {
    // Get current state of all years in local database
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();
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

    // Step 2: Check latest backups for all years
    final step2Result = await repository.startStep2(_lastDbUpdatedAtByYear);
    if (step2Result.isSuccess && step2Result.data != null) {
      _lastSyncedAtByYear = step2Result.data!.lastSyncedAtByYear;
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

    // Step 3: Import yearly backups if needed
    final step3Result = await repository.startStep3(
      step2Result.data?.yearlyBackupContents,
      _lastSyncedAtByYear,
      _lastDbUpdatedAtByYear,
    );

    if (!step3Result.isSuccess) return;

    // Re-fetch local timestamps after import (Step 3 may have updated DB with remote data)
    // This ensures Step 4 correctly identifies which years need uploading
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();
    notifyListeners();

    // Step 4: Upload new yearly backups
    final step4Result = await repository.startStep4(
      _lastSyncedAtByYear,
      _lastDbUpdatedAtByYear,
      step2Result.data?.yearlyBackupFiles, // Pass already-fetched backups
    );

    if (!step4Result.isSuccess) {
      if (step4Result.error?.type == BackupErrorType.authentication) {
        final connectionResult = await repository.checkConnection();
        _connectionStatus = connectionResult.data;
        notifyListeners();
      }
      return;
    }

    // Once all success, update sync timestamps
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();

    // Update _lastSyncedAtByYear from uploaded files
    if (step4Result.data?.uploadedYearlyFiles != null) {
      _lastSyncedAtByYear = step4Result.data!.uploadedYearlyFiles!.map(
        (year, file) => MapEntry(year, file.lastUpdatedAt),
      );
    } else {
      _lastSyncedAtByYear = _lastDbUpdatedAtByYear;
    }
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
