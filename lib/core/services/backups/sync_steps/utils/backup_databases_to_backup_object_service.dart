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
    int? year, // Optional: filter records by createdAt.year for v3 yearly backups
  }) async {
    debugPrint('BackupDatabasesToBackupObjectService#constructBackup year=$year');
    Map<String, dynamic> tables = await _constructTables(databases, year: year);
    debugPrint('BackupDatabasesToBackupObjectService#constructBackup ${tables.keys}');

    return BackupObject(
      tables: tables,
      year: year,
      fileInfo: BackupFileObject(
        createdAt: lastUpdatedAt,
        device: kDeviceInfo,
        version: year != null ? '3' : '2', // v3 for yearly, v2 for legacy
        year: year,
      ),
    );
  }

  static Future<Map<String, dynamic>> _constructTables(
    List<BaseDbAdapter> databases, {
    int? year,
  }) async {
    Map<String, CollectionDbModel<BaseDbModel>> tables = {};

    for (BaseDbAdapter db in databases) {
      final filters = year != null ? {'created_year': year} : null;
      CollectionDbModel<BaseDbModel>? items = await db.where(
        filters: filters,
        returnDeleted: true,
      );
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
