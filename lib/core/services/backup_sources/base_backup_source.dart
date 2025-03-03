import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_list_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backup_sources/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backup_sources/backup_to_file_service.dart';
import 'package:storypad/core/services/backup_sources/google_drive_backup_source.dart';

abstract class BaseBackupSource {
  String get cloudId;

  static final List<BaseBackupSource> sources = [
    GoogleDriveBackupSource(),
  ];

  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
    AssetDbModel.db,
  ];

  String? get email;
  String? get displayName;
  String? get smallImageUrl;
  String? get bigImageUrl;

  bool? isSignedIn;

  Future<bool> checkIsSignedIn();
  Future<bool> reauthenticate();
  Future<bool> signIn();
  Future<bool> signOut();
  Future<CloudFileObject?> uploadFile(String fileName, io.File file, {String? folderName});
  Future<CloudFileObject?> getLastestBackupFile();
  Future<CloudFileObject?> getFileByFileName(String fileName);
  Future<String?> getFileContent(CloudFileObject cloudFile);
  Future<CloudFileObject?> deleteCloudFile(String id);

  Future<void> authenticate() async {
    isSignedIn = await checkIsSignedIn();
    if (isSignedIn == true) await reauthenticate();
  }

  Future<CloudFileListObject?> fetchAllCloudFiles({
    String? nextToken,
  });

  Future<BackupObject?> getBackup(CloudFileObject cloudFile) async {
    String? contents = await getFileContent(cloudFile);

    try {
      if (contents != null) {
        dynamic decodedContents = jsonDecode(contents);
        return BackupObject.fromContents(decodedContents);
      }
    } catch (e) {
      debugPrint("$runtimeType#getBackup $e");
    }

    return null;
  }

  Future<CloudFileObject?> backup({
    required DateTime lastDbUpdatedAt,
  }) async {
    BackupObject backup = await BackupDatabasesToBackupObjectService.call(
      databases: databases,
      lastUpdatedAt: lastDbUpdatedAt,
    );

    final io.File file = await BackupToFileService.call(
      cloudId,
      backup,
    );

    return uploadFile(
      backup.fileInfo.fileNameWithExtention,
      file,
    );
  }
}
