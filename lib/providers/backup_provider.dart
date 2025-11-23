import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/backup_result.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';

class BackupProvider extends ChangeNotifier {
  BackupProvider() {
    recheckAndSync();

    step1MessageStream.listen((message) {
      AppLogger.d(
        '$runtimeType: step1 message success: ${message?.success} processing: ${message?.processing} message: ${message?.message}',
      );
      step1Message = message;
      notifyListeners();
    });

    step2MessageStream.listen((message) {
      AppLogger.d(
        '$runtimeType: step2 message success: ${message?.success} processing: ${message?.processing} message: ${message?.message}',
      );
      step2Message = message;
      notifyListeners();
    });

    step3MessageStream.listen((message) {
      AppLogger.d(
        '$runtimeType: step3 message success: ${message?.success} processing: ${message?.processing} message: ${message?.message}',
      );
      step3Message = message;
      notifyListeners();
    });

    step4MessageStream.listen((message) {
      AppLogger.d(
        '$runtimeType: step4 message success: ${message?.success} processing: ${message?.processing} message: ${message?.message}',
      );
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

  Stream<BackupSyncMessage?> get step1MessageStream => repository.step1MessageStream;
  Stream<BackupSyncMessage?> get step2MessageStream => repository.step2MessageStream;
  Stream<BackupSyncMessage?> get step3MessageStream => repository.step3MessageStream;
  Stream<BackupSyncMessage?> get step4MessageStream => repository.step4MessageStream;

  BackupSyncMessage? step1Message;
  BackupSyncMessage? step2Message;
  BackupSyncMessage? step3Message;
  BackupSyncMessage? step4Message;

  BackupConnectionStatus? _connectionStatus;
  BackupConnectionStatus? get connectionStatus => _connectionStatus;

  bool get allYearSynced =>
      _lastDbUpdatedAtByYear?.entries.every(
        (entry) => entry.value != null && entry.value == _lastSyncedAtByYear?[entry.key],
      ) ==
      true;

  bool get readyToSynced => _connectionStatus == BackupConnectionStatus.readyToSync && currentUser?.email != null;

  DateTime? get lastSyncedAt => _lastSyncedAtByYear?.values.whereType<DateTime>().fold<DateTime?>(
    null,
    (latest, current) => latest == null || current.isAfter(latest) ? current : latest,
  );

  DateTime? get lastDbUpdatedAt => _lastDbUpdatedAtByYear?.values.whereType<DateTime>().fold<DateTime?>(
    null,
    (latest, current) => latest == null || current.isAfter(latest) ? current : latest,
  );

  Map<int, DateTime?>? _lastSyncedAtByYear;
  Map<int, DateTime?>? get lastSyncedAtByYear => _lastSyncedAtByYear;

  Map<int, DateTime?>? _lastDbUpdatedAtByYear;
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
      AppLogger.d('Connection check failed: ${connectionResult.error!.message}');
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
      AppLogger.d('Sign-in failed: ${result!.error!.message}');
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
      AppLogger.d('Request scope failed: ${result!.error!.message}');
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
      AppLogger.d('Sign-out had issues: ${result!.error!.message}');
    }

    notifyListeners();
  }

  /// Synchronization flow for multiple devices (v3 yearly backups)
  ///
  /// Per-service sync flow:
  /// 1. For each signed-in service, execute Steps 1-4 sequentially:
  ///    - Step 1: Upload local images/audio assets to this service
  ///    - Step 2: Fetch and download yearly backups from this service if remote is newer
  ///    - Step 3: Import downloaded data (only records with newer timestamps)
  ///    - Step 4: Upload new/updated yearly backups to this service
  ///
  /// 2. Update global sync status using "Latest Wins" strategy:
  ///    - Track the most recent timestamp across all services per year
  ///    - UI shows "Synced" when local DB matches the latest remote timestamp
  ///
  /// 3. Handle failures gracefully:
  ///    - Service failures don't affect other services
  ///    - Auth failures trigger connection status update
  ///    - Failed services retry on next sync
  ///
  Future<void> _syncBackupAcrossDevices(String email) async {
    // Get current state of all years in local database
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();
    notifyListeners();

    // Process each service individually
    for (final service in services) {
      if (!service.isSignedIn) {
        AppLogger.d('Skipping service ${service.serviceType.displayName}: not signed in');
        continue;
      }

      final result = await repository.sync(service);
      if (!result.isSuccess) {
        if (result.error?.type == BackupErrorType.authentication) {
          final connectionResult = await repository.checkConnection();
          _connectionStatus = connectionResult.data;
        }

        // Skip to next service on failure
        continue;
      }

      // Update local DB timestamps after successful sync (in case import happened)
      _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();

      // Build sync timestamps map for this service:
      // 1. Start with remote timestamps from Step 2 (always available)
      // 2. Override with uploaded file timestamps from Step 4 (fresher, reflects actual upload)
      final uploadedYearlyFilesPerService = result.data?.uploadedYearlyFiles;
      final lastSyncedAtByYearPerService = result.data?.lastSyncedAtByYear ?? {};

      // Merge uploaded files (Step 4) over remote timestamps (Step 2)
      // Uploaded timestamps are more accurate as they reflect the actual state after upload
      if (uploadedYearlyFilesPerService != null) {
        for (var entry in uploadedYearlyFilesPerService.entries) {
          lastSyncedAtByYearPerService[entry.key] = entry.value.lastUpdatedAt;
        }
      }

      // Update global sync status using "Latest Wins" strategy:
      // - Compare timestamps across all services per year
      // - Keep the most recent timestamp (latest wins)
      // - This ensures UI reflects the true latest state across all backup services
      for (var entry in lastSyncedAtByYearPerService.entries) {
        final year = entry.key;
        final syncedAt = entry.value;
        final current = _lastSyncedAtByYear?[year];

        if (syncedAt != null && (current == null || syncedAt.isAfter(current))) {
          _lastSyncedAtByYear ??= {};
          _lastSyncedAtByYear?[year] = syncedAt;
        }
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
