import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/types/file_path_type.dart';

class BackupFileConstructor {
  Future<BackupObject> constructBackup({
    required List<BaseDbAdapter<BaseDbModel>> databases,
    required DateTime lastUpdatedAt,
  }) async {
    debugPrint('BackupFileConstructor#constructBackup');
    Map<String, dynamic> tables = await _constructTables(databases);
    debugPrint('BackupFileConstructor#constructBackup ${tables.keys}');

    return BackupObject(
      tables: tables,
      fileInfo: BackupFileObject(
        createdAt: lastUpdatedAt,
        device: kDeviceInfo,
      ),
    );
  }

  Future<io.File> constructFile(
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

  Future<Map<String, dynamic>> _constructTables(List<BaseDbAdapter> databases) async {
    Map<String, CollectionDbModel<BaseDbModel>> tables = {};

    for (BaseDbAdapter db in databases) {
      CollectionDbModel<BaseDbModel>? items = await db.where(options: {
        'all_changes': true,
      });

      tables[db.tableName] = items ?? CollectionDbModel(items: []);
    }

    return compute(_toJson, tables);
  }

  static Map<String, dynamic> _toJson(Map<String, CollectionDbModel<BaseDbModel>?> tables) {
    Map<String, dynamic> result = {};

    tables.forEach((key, value) {
      result[key] = value?.items.map((e) => e.toJson()).toList();
    });

    return result;
  }
}
