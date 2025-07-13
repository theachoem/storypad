import 'dart:async';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
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

  Future<bool> requestScope() => googleDriveClient.requestScope();
  Future<void> signIn() => googleDriveClient.signIn();
  Future<void> signOut() => googleDriveClient.signOut();

  void resetMessages() {
    step1ImagesUploader.reset();
    step2LatestBackupChecker.reset();
    step3LatestBackupImporter.reset();
    step4NewBackupUploader.reset();
  }

  Future<bool> startStep1() {
    return step1ImagesUploader.start(googleDriveClient);
  }

  Future<BackupLatestCheckerResponse> startStep2(DateTime? lastDbUpdatedAt) async {
    return step2LatestBackupChecker.start(
      googleDriveClient,
      lastDbUpdatedAt,
    );
  }

  Future<bool> startStep3(BackupObject? backupContent, DateTime? lastSyncedAt, DateTime? lastDbUpdatedAt) async {
    return step3LatestBackupImporter.start(
      backupContent,
      lastSyncedAt,
      lastDbUpdatedAt,
    );
  }

  Future<BackupUploaderResponse> startStep4(DateTime? lastSyncedAt, DateTime? lastDbUpdatedAt) async {
    return step4NewBackupUploader.start(
      googleDriveClient,
      lastSyncedAt,
      lastDbUpdatedAt,
    );
  }

  Future<BackupConnectionStatus?> checkConnection() async {
    if (!isSignedIn) return null;

    final hasInternet = await internetChecker.check();
    if (!hasInternet) return BackupConnectionStatus.noInternet;

    await googleDriveClient.reauthenticateIfNeeded();

    final bool canAccessRequestedScopes = await googleDriveClient.canAccessRequestedScopes();
    if (!canAccessRequestedScopes) return BackupConnectionStatus.needGoogleDrivePermission;

    return BackupConnectionStatus.readyToSync;
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
