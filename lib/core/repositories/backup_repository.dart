import 'dart:async';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
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
  ];

  final BackupImagesUploaderService step1;
  final BackupLatestCheckerService step2;
  final BackupImporterService step3;
  final BackupUploaderService step4;

  final InternetCheckerService internetChecker;
  final GoogleDriveClient googleDriveClient;

  BackupRepository({
    required this.step1,
    required this.step2,
    required this.step3,
    required this.step4,
    required this.internetChecker,
    required this.googleDriveClient,
  });

  static final BackupRepository appInstance = BackupRepository(
    step1: BackupImagesUploaderService(),
    step2: BackupLatestCheckerService(),
    step3: BackupImporterService(restoreService: RestoreBackupService.appInstance),
    step4: BackupUploaderService(),
    internetChecker: InternetCheckerService(),
    googleDriveClient: GoogleDriveClient(),
  );

  GoogleUserObject? get currentUser => googleDriveClient.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> initialize() async {
    await googleDriveClient.loadUserLocally();
  }

  Future<BackupConnectionStatus?> checkConnection() async {
    if (!isSignedIn) return null;

    final hasInternet = await internetChecker.check();
    if (!hasInternet) return BackupConnectionStatus.noInternet;

    await googleDriveClient.reauthenticate();

    final bool canAccessRequestedScopes = await googleDriveClient.canAccessRequestedScopes();
    if (!canAccessRequestedScopes) return BackupConnectionStatus.needGoogleDrivePermission;

    return BackupConnectionStatus.readyToSync;
  }

  Future<bool> sync(String email) async {
    step1.reset();
    step2.reset();
    step3.reset();
    step4.reset();

    final lastDbUpdatedAt = await getLastDbUpdatedAt();

    bool step1Success = await step1.start(googleDriveClient);
    if (!step1Success) return false;

    bool step2Success = await step2.start(googleDriveClient, lastDbUpdatedAt);
    if (!step2Success) return false;

    bool step3Success = await step3.start(step2.cacheBackup);
    if (!step3Success) return false;

    bool step4Success = await step4.start(googleDriveClient, lastDbUpdatedAt);
    if (!step4Success) return false;

    // clear cache backup from memory once completed.
    step2.clearCacheBackup();

    return true;
  }

  Future<void> signIn() => googleDriveClient.signIn();
  Future<void> signOut() => googleDriveClient.signOut();

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
    step1.controller.close();
    step2.controller.close();
    step3.controller.close();
    step4.controller.close();
  }
}
