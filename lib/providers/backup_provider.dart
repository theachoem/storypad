import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/assets/db_asset_loader_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/google_drive_cloud_service.dart';
import 'package:storypad/core/services/backups/google_drive_linux_cloud_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_importer_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_latest_checker_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/backup_result.dart';
import 'package:storypad/views/home/home_view.dart';

class BackupProvider extends ChangeNotifier with DebounchedCallback {
  BackupProvider() {
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

    _setupConnection().then((_) {
      // Auto sync if applicable.
      // Wait 1 second before calling to ensure home context is ready.
      Future.delayed(const Duration(seconds: 1), () {
        if (HomeView.homeContext?.mounted == true) {
          autoSync(setupConnection: false, context: HomeView.homeContext!);
        }
      });
    });
  }

  Future<void> _databaseListener() async {
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();
    notifyListeners();
  }

  static final BackupRepository repoInstance = _createRepoInstance();
  static BackupRepository _createRepoInstance() {
    return BackupRepository(
      restoreService: RestoreBackupService(),
      step1ImagesUploader: BackupImagesUploaderService(),
      step2LatestBackupChecker: BackupLatestCheckerService(),
      step3LatestBackupImporter: BackupImporterService(),
      step4NewBackupUploader: BackupUploaderService(),
      internetChecker: InternetCheckerService(),
      googleDriveService: _createGoogleDriveService(),
      importHistoryStorage: BackupImportHistoryStorage(),
    );
  }

  static BackupCloudService _createGoogleDriveService() {
    if (!kIsWeb && Platform.isLinux) return GoogleDriveLinuxCloudService();
    return GoogleDriveCloudService();
  }

  BackupRepository get repository => repoInstance;

  GoogleUserObject? get currentGoogleUser => repository.currentGoogleUser;
  bool get isSignedIn => repository.isSignedIn;

  /// Get all authenticated cloud service users for asset downloads
  List<CloudServiceUser> get availableUsers => repository.availableUsers;

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

  bool get readyToSynced => _connectionStatus == BackupConnectionStatus.readyToSync;

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
  List<BackupCloudService> get autoBackupServices =>
      repository.services.where((service) => service.autoBackupEnabled).toList();

  Future<void> _setupConnection() async {
    final connectionResult = await repository.checkConnection();
    _connectionStatus = connectionResult.data;
    notifyListeners();

    if (connectionResult.error != null) {
      AppLogger.d('Connection check failed: ${connectionResult.error!.message}');
    }
  }

  Future<void> autoSync({
    bool setupConnection = true,
    required BuildContext context,
  }) async {
    await recheckAndSync(
      setupConnection: setupConnection,
      services: autoBackupServices,
    );
  }

  Future<bool> recheckAndSync({
    bool setupConnection = true,
    required List<BackupCloudService> services,
  }) async {
    if (services.isEmpty) return false;
    if (_syncing) return false;

    _syncing = true;
    repository.resetMessages();
    notifyListeners();

    try {
      if (setupConnection) await _setupConnection();
      if (!readyToSynced) return false;

      return await _syncBackupAcrossDevices(services: services);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> signIn(
    BuildContext context,
    BackupServiceType serviceType,
  ) async {
    final result = await repository.signIn(serviceType);

    if (result.isSuccess == true) {
      AnalyticsService.instance.logSignInWithGoogle();

      _connectionStatus = BackupConnectionStatus.readyToSync;
      _lastSyncedAtByYear = null;
      _lastDbUpdatedAtByYear = null;
    } else if (result.error != null) {
      // Handle sign-in error - could show user-friendly message
      AppLogger.d('Sign-in failed: ${result.error!.message}');
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
    await recheckAndSync(
      services: [repository.getService(serviceType)],
    );
  }

  Future<void> signOut(
    BuildContext context,
    BackupServiceType serviceType,
  ) async {
    final result = await MessengerService.of(context).showLoading<BackupResult<void>>(
      debugSource: '$runtimeType#signOut',
      future: () => repository.signOut(serviceType),
    );

    AnalyticsService.instance.logSignOut();

    _connectionStatus = null;
    _lastSyncedAtByYear = null;
    _lastDbUpdatedAtByYear = null;

    step1Message = null;
    step2Message = null;
    step3Message = null;
    step4Message = null;

    if (result?.error != null) {
      AppLogger.d('Sign-out had issues: ${result!.error!.message}');
    }

    DbAssetLoaderService.instance.clear();
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
  Future<bool> _syncBackupAcrossDevices({
    required List<BackupCloudService> services,
  }) async {
    // Get current state of all years in local database
    _lastDbUpdatedAtByYear = await repository.getLastDbUpdatedAtByYear();
    notifyListeners();

    var attemptedSync = false;
    var allSyncsSucceeded = true;

    // Process each service individually
    for (final service in services) {
      if (!service.isSignedIn) {
        AppLogger.d('Skipping service ${service.serviceType.displayName}: not signed in');
        continue;
      }

      final serviceId = service.serviceType.id;
      attemptedSync = true;
      FirebaseCrashlytics.instance.log('$runtimeType#_syncBackupAcrossDevices[$serviceId]: started');

      final result = await repository.sync(service);
      if (!result.isSuccess) {
        allSyncsSucceeded = false;
        FirebaseCrashlytics.instance.log(
          '$runtimeType#_syncBackupAcrossDevices[$serviceId]: failed — ${result.error?.message}',
        );
        if (result.error?.type == BackupErrorType.authentication) {
          final connectionResult = await repository.checkConnection();
          _connectionStatus = connectionResult.data;
        }

        // Skip to next service on failure
        continue;
      }

      FirebaseCrashlytics.instance.log('$runtimeType#_syncBackupAcrossDevices[$serviceId]: succeeded');

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
    return attemptedSync && allSyncsSucceeded;
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
