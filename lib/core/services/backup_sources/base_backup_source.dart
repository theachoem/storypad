import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_list_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backup_sources/backup_file_constructor.dart';

abstract class BaseBackupSource {
  String get cloudId;

  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
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
  Future<CloudFileObject?> saveFile(String fileName, io.File file);
  Future<CloudFileObject?> getLastestBackupFile();
  Future<CloudFileObject?> getFileByFileName(String fileName);
  Future<String?> getFileContent(CloudFileObject cloudFile);
  Future<void> deleteCloudFile(String id);

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
    BackupObject backup = await BackupFileConstructor().constructBackup(
      databases: databases,
      lastUpdatedAt: lastDbUpdatedAt,
    );

    final io.File file = await BackupFileConstructor().constructFile(
      cloudId,
      backup,
    );

    return saveFile(
      backup.fileInfo.fileNameWithExtention,
      file,
    );
  }
}
