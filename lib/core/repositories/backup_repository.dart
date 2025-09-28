import 'dart:async';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/types/backup_connection_status.dart';

// ignore: depend_on_referenced_packages
import 'package:storypad/core/services/backup_sync_steps/backup_importer_service.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_latest_checker_service.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_uploader_service.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/types/backup_result.dart';

class BackupRepository {
  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
    TemplateDbModel.db,
    AssetDbModel.db,
    RelaxSoundMixModel.db,
  ];

  final BackupImagesUploaderService step1ImagesUploader;
  final BackupLatestCheckerService step2LatestBackupChecker;
  final BackupImporterService step3LatestBackupImporter;
  final BackupUploaderService step4NewBackupUploader;

  final InternetCheckerService internetChecker;
  final GoogleDriveClient googleDriveClient;

  BackupRepository({
    required this.step1ImagesUploader,
    required this.step2LatestBackupChecker,
    required this.step3LatestBackupImporter,
    required this.step4NewBackupUploader,
    required this.internetChecker,
    required this.googleDriveClient,
  });

  static final BackupRepository appInstance = BackupRepository(
    step1ImagesUploader: BackupImagesUploaderService(),
    step2LatestBackupChecker: BackupLatestCheckerService(),
    step3LatestBackupImporter: BackupImporterService(restoreService: RestoreBackupService.appInstance),
    step4NewBackupUploader: BackupUploaderService(),
    internetChecker: InternetCheckerService(),
    googleDriveClient: GoogleDriveClient(),
  );

  // currentUser & isSignedIn are load in initializer - before rendering UI.
  GoogleUserObject? get currentUser => googleDriveClient.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<BackupResult<bool>> requestScope() async {
    try {
      final result = await googleDriveClient.requestScope();
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to request scope: $e',
        context: 'requestScope',
      ));
    }
  }

  Future<BackupResult<bool>> signIn() async {
    try {
      final result = await googleDriveClient.signIn();
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to sign in: $e',
        context: 'signIn',
      ));
    }
  }

  Future<BackupResult<void>> signOut() async {
    try {
      await googleDriveClient.signOut();
      return const BackupResult.success(null);
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to sign out: $e',
        context: 'signOut',
      ));
    }
  }

  void resetMessages() {
    step1ImagesUploader.reset();
    step2LatestBackupChecker.reset();
    step3LatestBackupImporter.reset();
    step4NewBackupUploader.reset();
  }

  Future<BackupResult<bool>> startStep1() async {
    try {
      final result = await step1ImagesUploader.start(googleDriveClient);
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      if (e.requiresSignOut) {
        await googleDriveClient.signOut();
      }
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to upload images: $e',
        context: 'startStep1',
      ));
    }
  }

  Future<BackupResult<BackupLatestCheckerResponse>> startStep2(DateTime? lastDbUpdatedAt) async {
    try {
      final result = await step2LatestBackupChecker.start(
        googleDriveClient,
        lastDbUpdatedAt,
      );
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      if (e.requiresSignOut) {
        await googleDriveClient.signOut();
      }
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to check latest backup: $e',
        context: 'startStep2',
      ));
    }
  }

  Future<BackupResult<bool>> startStep3(
      BackupObject? backupContent, DateTime? lastSyncedAt, DateTime? lastDbUpdatedAt) async {
    try {
      final result = await step3LatestBackupImporter.start(
        backupContent,
        lastSyncedAt,
        lastDbUpdatedAt,
      );
      return BackupResult.success(result);
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to import backup: $e',
        context: 'startStep3',
      ));
    }
  }

  Future<BackupResult<BackupUploaderResponse>> startStep4(DateTime? lastSyncedAt, DateTime? lastDbUpdatedAt) async {
    try {
      final result = await step4NewBackupUploader.start(
        googleDriveClient,
        lastSyncedAt,
        lastDbUpdatedAt,
      );
      return BackupResult.success(result);
    } on exp.AuthException catch (e) {
      if (e.requiresSignOut) {
        await googleDriveClient.signOut();
      }
      return BackupResult.failure(BackupError.fromException(e));
    } catch (e) {
      return BackupResult.failure(BackupError.unknown(
        'Failed to upload backup: $e',
        context: 'startStep4',
      ));
    }
  }

  Future<BackupResult<BackupConnectionStatus>> checkConnection() async {
    try {
      if (!isSignedIn) {
        return BackupResult.failure(BackupError.authentication(
          'User not signed in',
          context: 'checkConnection',
        ));
      }

      final hasInternet = await internetChecker.check();
      if (!hasInternet) {
        return const BackupResult.success(BackupConnectionStatus.noInternet);
      }

      await googleDriveClient.reauthenticateIfNeeded();
      await googleDriveClient.canAccessRequestedScopes();

      return const BackupResult.success(BackupConnectionStatus.readyToSync);
    } on exp.AuthException catch (e) {
      if (e.requiresSignOut) {
        await googleDriveClient.signOut();
      }

      final status = switch (e.type) {
        exp.AuthExceptionType.tokenExpired => BackupConnectionStatus.needGoogleDrivePermission,
        exp.AuthExceptionType.tokenRevoked => BackupConnectionStatus.needGoogleDrivePermission,
        exp.AuthExceptionType.insufficientScopes => BackupConnectionStatus.needGoogleDrivePermission,
        _ => BackupConnectionStatus.unknownError,
      };

      return BackupResult.success(status);
    } on exp.NetworkException {
      return const BackupResult.success(BackupConnectionStatus.noInternet);
    } catch (e) {
      return const BackupResult.success(BackupConnectionStatus.unknownError);
    }
  }

  Future<DateTime?> getLastDbUpdatedAt() async {
    DateTime? updatedAt;

    for (var db in BackupRepository.databases) {
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

  void dispose() {
    step1ImagesUploader.controller.close();
    step2LatestBackupChecker.controller.close();
    step3LatestBackupImporter.controller.close();
    step4NewBackupUploader.controller.close();
  }
}
