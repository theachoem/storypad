import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/backup_object.dart';

class BackupDatabasesToBackupObjectService {
  static Future<BackupObject> call({
    required List<BaseDbAdapter<BaseDbModel>> databases,
    required DateTime lastUpdatedAt,
  }) async {
    debugPrint('BackupDatabasesToBackupObjectService#constructBackup');
    Map<String, dynamic> tables = await _constructTables(databases);
    Map<String, Map<String, int>> deletedRecords = await _constructDeletedRecords(databases);
    debugPrint('BackupDatabasesToBackupObjectService#constructBackup ${tables.keys}');

    return BackupObject(
      tables: tables,
      deletedRecords: deletedRecords,
      fileInfo: BackupFileObject(
        createdAt: lastUpdatedAt,
        device: kDeviceInfo,
      ),
    );
  }

  static Future<Map<String, Map<String, int>>> _constructDeletedRecords(List<BaseDbAdapter> databases) async {
    Map<String, Map<String, int>> tables = {};

    for (BaseDbAdapter db in databases) {
      tables[db.tableName] = await db.getDeletedRecords();
    }

    return tables;
  }

  static Future<Map<String, dynamic>> _constructTables(List<BaseDbAdapter> databases) async {
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
