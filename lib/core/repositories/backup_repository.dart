import 'dart:async';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/objects/icloud_user_object.dart';
import 'package:storypad/core/objects/nextcloud_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/nextcloud_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_messenger.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';
import 'package:storypad/core/types/backup_connection_status.dart';

// ignore: depend_on_referenced_packages
import 'package:storypad/core/services/backups/sync_steps/backup_importer_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_latest_checker_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_uploader_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/types/backup_result.dart';

/// [hasInternet] false makes [statusByService] moot — nothing can succeed
/// offline, so every signed-in service is reported as [BackupConnectionStatus.noInternet]
/// without attempting a per-service check.
typedef ConnectionCheckResult = ({bool hasInternet, Map<BackupServiceType, BackupConnectionStatus> statusByService});

class SyncResponse {
  final Map<int, CloudFileObject>? uploadedYearlyFiles;
  final Map<int, DateTime?>? lastSyncedAtByYear;

  SyncResponse({
    this.uploadedYearlyFiles,
    this.lastSyncedAtByYear,
  });
}

enum UserChangeType {
  signIn,
  signOut,
}

class BackupRepository {
  /// Broadcasts whenever a cloud service user signs in or out.
  /// Consumers can re-read [services] to get the latest authenticated users.
  final StreamController<UserChangeType> _userChangesController = StreamController<UserChangeType>.broadcast();
  Stream<UserChangeType> get userChanges => _userChangesController.stream;

  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
    TagCategoryDbModel.db,
    EventDbModel.db,
    TemplateDbModel.db,
    AssetDbModel.db,
    RelaxSoundMixModel.db,
  ];

  final RestoreBackupService restoreService;
  final BackupCloudService googleDriveService;
  final NextcloudCloudService nextcloudService;

  /// Null on platforms where iCloud doesn't conceptually exist (Android,
  /// Linux, Windows) — unlike Drive's Linux stub, there's no always-registered
  /// disabled placeholder for iCloud; it's simply absent from [services]
  /// there, so no connect tile renders. See `BackupProvider._createICloudService`.
  final BackupCloudService? icloudService;
  final BackupSyncMessenger messenger;

  final BackupImagesUploaderService _step1ImagesUploader;
  final BackupLatestCheckerService _step2LatestBackupChecker;
  final BackupImporterService _step3LatestBackupImporter;
  final BackupUploaderService _step4NewBackupUploader;
  final InternetCheckerService _internetChecker;
  final BackupImportHistoryStorage _importHistoryStorage;

  BackupRepository({
    required this.googleDriveService,
    required this.nextcloudService,
    required this.icloudService,
    required this.restoreService,
    required this.messenger,
    required BackupImagesUploaderService step1ImagesUploader,
    required BackupLatestCheckerService step2LatestBackupChecker,
    required BackupImporterService step3LatestBackupImporter,
    required BackupUploaderService step4NewBackupUploader,
    required InternetCheckerService internetChecker,
    required BackupImportHistoryStorage importHistoryStorage,
  }) : _step1ImagesUploader = step1ImagesUploader,
       _step2LatestBackupChecker = step2LatestBackupChecker,
       _step3LatestBackupImporter = step3LatestBackupImporter,
       _step4NewBackupUploader = step4NewBackupUploader,
       _internetChecker = internetChecker,
       _importHistoryStorage = importHistoryStorage;

  Future<void> initialize() async {
    await googleDriveService.initialize();
    await nextcloudService.initialize();
    await icloudService?.initialize();
  }

  // currentUser & isSignedIn are load in initializer - before rendering UI.
  GoogleUserObject? get currentGoogleUser => googleDriveService.currentUser as GoogleUserObject?;
  NextcloudUserObject? get currentNextcloudUser => nextcloudService.currentUser;
  ICloudUserObject? get currentICloudUser => icloudService?.currentUser as ICloudUserObject?;
  bool get isSignedIn => availableUsers.isNotEmpty;

  /// Get all authenticated cloud service users for asset downloads
  List<CloudServiceUser> get availableUsers {
    final users = <CloudServiceUser>[];

    for (final service in services) {
      if (service.currentUser != null) users.add(service.currentUser!);
    }

    return users;
  }

  /// Nextcloud's auth is a server/username/app-password form rather than a
  /// no-argument OAuth flow, so the connect sheet calls this directly instead
  /// of going through the generic [signIn].
  Future<BackupResult<bool>> connectNextcloud({
    required String serverUrl,
    required String username,
    required String appPassword,
    String? folderName,
  }) async {
    try {
      final result = await nextcloudService.connect(
        serverUrl: serverUrl,
        username: username,
        appPassword: appPassword,
        folderName: folderName,
      );
      if (result) _userChangesController.add(UserChangeType.signIn);
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(
        BackupError.unknown(
          'Failed to connect to Nextcloud: $e',
          context: 'connectNextcloud',
        ),
      );
    }
  }

  Stream<BackupSyncMessage> get syncMessages => messenger.messages;

  List<BackupCloudService> get services => [
    ?icloudService,
    googleDriveService,
    nextcloudService,
  ];

  BackupCloudService getService(BackupServiceType serviceType) {
    return services.where((service) => service.serviceType == serviceType).first;
  }

  Future<BackupResult<bool>> requestScope() async {
    try {
      final result = await googleDriveService.requestScope();
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(
        BackupError.unknown(
          'Failed to request scope: $e',
          context: 'requestScope',
        ),
      );
    }
  }

  Future<BackupResult<bool>> signIn(BackupServiceType serviceType) async {
    try {
      final result = await getService(serviceType).signIn();
      if (result) _userChangesController.add(UserChangeType.signIn);
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(
        BackupError.unknown(
          'Failed to sign in: $e',
          context: 'signIn',
        ),
      );
    }
  }

  Future<BackupResult<void>> signOut(BackupServiceType serviceType) async {
    try {
      await getService(serviceType).signOut();
      await _importHistoryStorage.clearService(serviceType);
      _userChangesController.add(UserChangeType.signOut);
      return const BackupResult.success(null);
    } catch (e) {
      return BackupResult.failure(
        BackupError.unknown(
          'Failed to sign out: $e',
          context: 'signOut',
        ),
      );
    }
  }

  /// Execute complete 4-step sync process for a single backup service
  ///
  /// Steps:
  /// 1. Upload images/audio assets to this service
  /// 2. Check and download latest yearly backups from this service
  /// 3. Import downloaded changes (only newer records)
  /// 4. Upload new/updated yearly backups to this service
  ///
  /// [uploadAssets] false defers media uploads (see MediaSyncOption) — steps 2-4
  /// still run in full, and the deferred assets upload on a later unmetered run.
  ///
  /// Throws: Never throws - all errors wrapped in BackupResult.failure
  Future<BackupResult<SyncResponse>> sync(
    BackupCloudService service, {
    required bool uploadAssets,
  }) async {
    AppLogger.d('🔄 Starting sync for service: ${service.serviceType.displayName}');

    // Step 1: Upload images for this service.
    // Runs before getLastDbUpdatedAtByYear() below on purpose: uploading bumps
    // each asset's updatedAt, so the years it touched come out dirty here and
    // step 4 republishes them with the new cloud pointers.
    final step1Result = await startStep1(service, uploadAssets: uploadAssets);
    if (!step1Result.isSuccess) {
      AppLogger.warning('Step 1 failed for ${service.serviceType.displayName}: ${step1Result.error!.message}');
      return BackupResult.failure(step1Result.error!);
    }

    // Get current state of all years in local database
    var lastDbUpdatedAtByYear = await getLastDbUpdatedAtByYear();

    // Step 2: Check and download latest backups for this service
    final step2Result = await startStep2(service, lastDbUpdatedAtByYear);

    if (!step2Result.isSuccess) {
      AppLogger.warning('Step 2 failed for ${service.serviceType.displayName}: ${step2Result.error!.message}');
      return BackupResult.failure(step2Result.error!);
    }

    final lastSyncedAtByYear = step2Result.data?.lastSyncedAtByYear;
    final backupCloudFileByYear = step2Result.data?.backupCloudFileByYear;
    final backupContentsByYear = step2Result.data?.backupContentsByYear;

    // Step 3: Import yearly backups if needed
    if (lastSyncedAtByYear != null && lastSyncedAtByYear.isNotEmpty) {
      final step3Result = await startStep3(
        backupContentsByYear,
        lastSyncedAtByYear,
        lastDbUpdatedAtByYear,
        service,
      );

      if (!step3Result.isSuccess) {
        AppLogger.warning('Step 3 failed for ${service.serviceType.displayName}: ${step3Result.error!.message}');
        return BackupResult.failure(step3Result.error!);
      }

      // Re-fetch local timestamps after import (Step 3 may have updated DB with remote data)
      lastDbUpdatedAtByYear = await getLastDbUpdatedAtByYear();
    } else {
      AppLogger.d('No backups to sync for ${service.serviceType.displayName} - already up to date');
    }

    // Step 4: Upload new yearly backups to THIS service
    final step4Result = await startStep4(
      service,
      lastSyncedAtByYear, // Use remote timestamps from Step 2
      lastDbUpdatedAtByYear,
      backupCloudFileByYear,
    );

    if (!step4Result.isSuccess) {
      if (step4Result.error?.type == BackupErrorType.authentication) {
        AppLogger.critical('Auth failure during Step 4 upload: ${step4Result.error!.message}');
      } else {
        AppLogger.error('Step 4 upload failed for ${service.serviceType.displayName}: ${step4Result.error!.message}');
      }
      return BackupResult.failure(step4Result.error!);
    }

    return BackupResult.success(
      SyncResponse(
        uploadedYearlyFiles: step4Result.data?.uploadedYearlyFiles,
        lastSyncedAtByYear: lastSyncedAtByYear,
      ),
    );
  }

  Future<BackupResult<bool>> startStep1(
    BackupCloudService service, {
    required bool uploadAssets,
  }) async {
    try {
      final result = await _step1ImagesUploader.start(service, uploadAssets: uploadAssets, allServices: services);
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      // Credentials are kept even on a revoked grant — only an explicit
      // "Sign out" or a successful reconnect changes stored state now, so the
      // UI can offer a reconnect action instead of forcing a fresh connect.
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      if (e is ArgumentError) {
        AppLogger.critical(e.message.toString(), stackTrace: e.stackTrace);
      } else if (e is TypeError) {
        AppLogger.critical(e.toString(), stackTrace: e.stackTrace);
      } else {
        AppLogger.error("${e.runtimeType} error: ${e.toString()}");
      }
      return BackupResult.failure(
        BackupError.unknown(
          'Failed to upload images: $e',
          context: 'startStep1',
        ),
      );
    }
  }

  Future<BackupResult<BackupLatestCheckerResponse>> startStep2(
    BackupCloudService service,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
  ) async {
    try {
      final result = await _step2LatestBackupChecker.start(
        service,
        _importHistoryStorage,
        lastDbUpdatedAtByYear,
      );
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      // Credentials are kept even on a revoked grant — only an explicit
      // "Sign out" or a successful reconnect changes stored state now, so the
      // UI can offer a reconnect action instead of forcing a fresh connect.
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      if (e is ArgumentError) {
        AppLogger.critical(e.message.toString(), stackTrace: e.stackTrace);
      } else if (e is TypeError) {
        AppLogger.critical(e.toString(), stackTrace: e.stackTrace);
      } else {
        AppLogger.error("${e.runtimeType} error: ${e.toString()}");
      }

      return BackupResult.failure(
        BackupError.unknown(
          'Failed to check latest backup: $e',
          context: 'startStep2',
        ),
      );
    }
  }

  Future<BackupResult<bool>> startStep3(
    Map<int, BackupObject>? backupContentsByYear,
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
    BackupCloudService service,
  ) async {
    try {
      final result = await _step3LatestBackupImporter.start(
        restoreService,
        service,
        _importHistoryStorage,
        backupContentsByYear,
        lastSyncedAtByYear,
        lastDbUpdatedAtByYear,
      );
      return BackupResult.success(result);
    } catch (e) {
      if (e is ArgumentError) {
        AppLogger.critical(e.message.toString(), stackTrace: e.stackTrace);
      } else if (e is TypeError) {
        AppLogger.critical(e.toString(), stackTrace: e.stackTrace);
      } else {
        AppLogger.error("${e.runtimeType} error: ${e.toString()}");
      }

      return BackupResult.failure(
        BackupError.unknown(
          'Failed to import backup: $e',
          context: 'startStep3',
        ),
      );
    }
  }

  Future<BackupResult<BackupUploaderResponse>> startStep4(
    BackupCloudService service,
    Map<int, DateTime?>? lastSyncedAtByYear,
    Map<int, DateTime?>? lastDbUpdatedAtByYear,
    Map<int, CloudFileObject>? existingYearlyBackups,
  ) async {
    try {
      if (!service.isSignedIn) {
        return BackupResult.failure(
          BackupError.authentication(
            'Service ${service.serviceType.displayName} is not signed in.',
            context: 'startStep4',
          ),
        );
      }

      final result = await _step4NewBackupUploader.startStep4(
        service,
        _importHistoryStorage,
        lastSyncedAtByYear,
        lastDbUpdatedAtByYear,
        existingYearlyBackups,
      );
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      // Credentials are kept even on a revoked grant — only an explicit
      // "Sign out" or a successful reconnect changes stored state now, so the
      // UI can offer a reconnect action instead of forcing a fresh connect.
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      if (e is ArgumentError) {
        AppLogger.critical(e.message.toString(), stackTrace: e.stackTrace);
      } else if (e is TypeError) {
        AppLogger.critical(e.toString(), stackTrace: e.stackTrace);
      } else {
        AppLogger.error("${e.runtimeType} error: ${e.toString()}");
      }

      return BackupResult.failure(
        BackupError.unknown(
          'Failed to upload backup: $e',
          context: 'startStep4',
        ),
      );
    }
  }

  /// Checks every signed-in service independently — one service throwing
  /// (auth failure, or anything unexpected) no longer prevents checking the
  /// rest, and credentials are never wiped here regardless of outcome.
  ///
  /// iCloud is included even while *not* currently signed in: unlike Drive/
  /// Nextcloud (where "not signed in" means there's nothing to check),
  /// [ICloudCloudService.reauthenticateIfNeeded] is a cheap local
  /// availability re-probe, not a network credential check — and it's the
  /// only way an iCloud tile ever recovers on its own after the user enables
  /// iCloud Drive in Settings and returns to the app (this runs on every app
  /// resume via [AutoSyncTriggerService]). Without this, the tile would stay
  /// stuck on "unavailable" until the user happened to tap it again.
  Future<BackupResult<ConnectionCheckResult>> checkConnection() async {
    final checkableServices = services
        .where((service) => service.isSignedIn || service.serviceType == BackupServiceType.icloud)
        .toList();

    if (checkableServices.isEmpty) {
      return BackupResult.failure(
        BackupError.authentication(
          'User not signed in',
          context: 'checkConnection',
        ),
      );
    }

    bool hasInternet;
    try {
      hasInternet = await _internetChecker.check();
    } catch (e) {
      hasInternet = false;
    }

    if (!hasInternet) {
      return BackupResult.success((
        hasInternet: false,
        statusByService: {
          for (final service in checkableServices) service.serviceType: BackupConnectionStatus.noInternet,
        },
      ));
    }

    final statusByService = <BackupServiceType, BackupConnectionStatus>{};

    for (final service in checkableServices) {
      try {
        await service.reauthenticateIfNeeded();
        await service.canAccessRequestedScopes();
        statusByService[service.serviceType] = BackupConnectionStatus.readyToSync;
      } on exp.AuthException catch (e) {
        statusByService[service.serviceType] = switch (e.type) {
          exp.AuthExceptionType.tokenExpired => BackupConnectionStatus.needServicePermission,
          exp.AuthExceptionType.tokenRevoked => BackupConnectionStatus.needServicePermission,
          exp.AuthExceptionType.insufficientScopes => BackupConnectionStatus.needServicePermission,
          // Still off in Settings — an expected, recoverable state for
          // iCloud specifically, not an unknown/broken one.
          exp.AuthExceptionType.signInRequired => BackupConnectionStatus.needServicePermission,
          _ => BackupConnectionStatus.unknownError,
        };
      } on exp.NetworkException {
        statusByService[service.serviceType] = BackupConnectionStatus.noInternet;
      } catch (e) {
        statusByService[service.serviceType] = BackupConnectionStatus.unknownError;
      }
    }

    return BackupResult.success((hasInternet: true, statusByService: statusByService));
  }

  /// How many distinct local assets are still waiting to reach any signed-in
  /// service — i.e. media deferred by the Wi-Fi-only setting.
  ///
  /// Counts distinct assets rather than summing per service, so an asset
  /// pending on two services isn't reported twice.
  Future<int> pendingMediaCount() async {
    final Set<int> assetIds = {};

    for (final service in services) {
      if (!service.isSignedIn) continue;

      final pending = await _step1ImagesUploader.pendingAssets(service, allServices: services);
      assetIds.addAll(pending.map((asset) => asset.id));
    }

    return assetIds.length;
  }

  Future<Map<int, DateTime?>> getLastDbUpdatedAtByYear() async {
    final Map<int, DateTime?> result = {};

    for (var db in BackupRepository.databases) {
      final Map<int, DateTime?> yearUpdates = await db.getLastUpdatedAtByYear();

      for (var entry in yearUpdates.entries) {
        final year = entry.key;
        final dateTime = entry.value;

        if (dateTime == null) continue;

        if (result[year] == null || dateTime.isAfter(result[year]!)) {
          result[year] = dateTime;
        }
      }
    }

    return result;
  }

  void dispose() {
    _userChangesController.close();
    messenger.dispose();
  }
}
