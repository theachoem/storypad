import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/types/file_path_type.dart';

class BackupToFileService {
  static Future<io.File> call(
    String cloudStorageId,
    BackupObject backup,
  ) async {
    io.Directory parent = io.Directory("${kSupportDirectory.path}/${FilePathType.backups.name}");

    var file = io.File("${parent.path}/$cloudStorageId.json");
    if (!file.existsSync()) {
      await file.create(recursive: true);
      debugPrint('BackupFileConstructor#constructFile createdFile: ${file.path.replaceAll(' ', '%20')}');
    }

    debugPrint('BackupFileConstructor#constructFile encodingJson');
    String encodedJson = jsonEncode(backup.toContents());
    debugPrint('BackupFileConstructor#constructFile encodedJson');

    return file.writeAsString(encodedJson);
  }
}
