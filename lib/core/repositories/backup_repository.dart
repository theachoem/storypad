import 'dart:async';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';
import 'package:storypad/core/types/backup_connection_status.dart';

// ignore: depend_on_referenced_packages
import 'package:storypad/core/services/backups/sync_steps/backup_importer_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_latest_checker_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_uploader_service.dart';
import 'package:storypad/core/services/backups/google_drive_cloud_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/types/backup_result.dart';

class SyncResponse {
  final Map<int, CloudFileObject>? uploadedYearlyFiles;
  final Map<int, DateTime?>? lastSyncedAtByYear;

  SyncResponse({
    this.uploadedYearlyFiles,
    this.lastSyncedAtByYear,
  });
}

class BackupRepository {
  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
    EventDbModel.db,
    TemplateDbModel.db,
    AssetDbModel.db,
    RelaxSoundMixModel.db,
  ];

  final RestoreBackupService restoreService;
  final GoogleDriveCloudService googleDriveService;

  final BackupImagesUploaderService _step1ImagesUploader;
  final BackupLatestCheckerService _step2LatestBackupChecker;
  final BackupImporterService _step3LatestBackupImporter;
  final BackupUploaderService _step4NewBackupUploader;
  final InternetCheckerService _internetChecker;
  final BackupImportHistoryStorage _importHistoryStorage;

  BackupRepository({
    required this.googleDriveService,
    required this.restoreService,
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

  static final BackupRepository appInstance = _createInstance();

  static BackupRepository _createInstance() {
    return BackupRepository(
      restoreService: RestoreBackupService(),
      step1ImagesUploader: BackupImagesUploaderService(),
      step2LatestBackupChecker: BackupLatestCheckerService(),
      step3LatestBackupImporter: BackupImporterService(),
      step4NewBackupUploader: BackupUploaderService(),
      internetChecker: InternetCheckerService(),
      googleDriveService: GoogleDriveCloudService(),
      importHistoryStorage: BackupImportHistoryStorage(),
    );
  }

  Future<void> initialize() async {
    await googleDriveService.initialize();
  }

  // currentUser & isSignedIn are load in initializer - before rendering UI.
  GoogleUserObject? get currentUser => googleDriveService.currentUser;
  bool get isSignedIn => currentUser != null;

  Stream<BackupSyncMessage?> get step1MessageStream => _step1ImagesUploader.message;
  Stream<BackupSyncMessage?> get step2MessageStream => _step2LatestBackupChecker.message;
  Stream<BackupSyncMessage?> get step3MessageStream => _step3LatestBackupImporter.message;
  Stream<BackupSyncMessage?> get step4MessageStream => _step4NewBackupUploader.message;

  List<BackupCloudService> get services => [
    googleDriveService,
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

  void resetMessages() {
    _step1ImagesUploader.reset();
    _step2LatestBackupChecker.reset();
    _step3LatestBackupImporter.reset();
    _step4NewBackupUploader.reset();
  }

  /// Execute complete 4-step sync process for a single backup service
  ///
  /// Steps:
  /// 1. Upload images/audio assets to this service
  /// 2. Check and download latest yearly backups from this service
  /// 3. Import downloaded changes (only newer records)
  /// 4. Upload new/updated yearly backups to this service
  ///
  /// Throws: Never throws - all errors wrapped in BackupResult.failure
  Future<BackupResult<SyncResponse>> sync(BackupCloudService service) async {
    AppLogger.d('🔄 Starting sync for service: ${service.serviceType.displayName}');

    // Step 1: Upload images for this service
    final step1Result = await startStep1(service);
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

  Future<BackupResult<bool>> startStep1(BackupCloudService service) async {
    try {
      final result = await _step1ImagesUploader.start(service);
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      if (e.requiresSignOut && e.serviceType != null) await signOut(e.serviceType!);
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
      if (e.requiresSignOut && e.serviceType != null) await signOut(e.serviceType!);
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
      if (e.requiresSignOut && e.serviceType != null) await signOut(e.serviceType!);
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

  Future<BackupResult<BackupConnectionStatus>> checkConnection() async {
    try {
      if (!isSignedIn) {
        return BackupResult.failure(
          BackupError.authentication(
            'User not signed in',
            context: 'checkConnection',
          ),
        );
      }

      final hasInternet = await _internetChecker.check();
      if (!hasInternet) {
        return const BackupResult.success(BackupConnectionStatus.noInternet);
      }

      // Check connection for all services
      for (final service in services) {
        if (!service.isSignedIn) continue;

        try {
          await service.reauthenticateIfNeeded();
          await service.canAccessRequestedScopes();
        } on exp.AuthException catch (e) {
          if (e.requiresSignOut && e.serviceType != null) await signOut(e.serviceType!);

          final status = switch (e.type) {
            exp.AuthExceptionType.tokenExpired => BackupConnectionStatus.needGoogleDrivePermission,
            exp.AuthExceptionType.tokenRevoked => BackupConnectionStatus.needGoogleDrivePermission,
            exp.AuthExceptionType.insufficientScopes => BackupConnectionStatus.needGoogleDrivePermission,
            _ => BackupConnectionStatus.unknownError,
          };

          return BackupResult.success(status);
        }
      }

      return const BackupResult.success(BackupConnectionStatus.readyToSync);
    } on exp.NetworkException {
      return const BackupResult.success(BackupConnectionStatus.noInternet);
    } catch (e) {
      return const BackupResult.success(BackupConnectionStatus.unknownError);
    }
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
    _step1ImagesUploader.controller.close();
    _step2LatestBackupChecker.controller.close();
    _step3LatestBackupImporter.controller.close();
    _step4NewBackupUploader.controller.close();
  }
}
