import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/search_filter_object.dart';

class BackupDatabasesToBackupObjectService {
  static Future<BackupObject> call({
    required List<BaseDbAdapter<BaseDbModel>> databases,
    required DateTime lastUpdatedAt,
    SearchFilterObject? storyFilter,
    required bool hasCompression,
    int? year, // Optional: filter records by createdAt.year for v3 yearly backups
  }) async {
    debugPrint('BackupDatabasesToBackupObjectService#constructBackup year=$year hasCompression=$hasCompression');
    Map<String, dynamic> tables = await _constructTables(databases, storyFilter: storyFilter, year: year);
    debugPrint('BackupDatabasesToBackupObjectService#constructBackup ${tables.keys}');

    return BackupObject(
      tables: tables,
      year: year,
      fileInfo: BackupFileObject(
        createdAt: lastUpdatedAt,
        device: kDeviceInfo,
        version: year != null ? '3' : '2', // v3 for yearly, v2 for legacy
        year: year,
        hasCompression: hasCompression,
      ),
    );
  }

  static Future<Map<String, dynamic>> _constructTables(
    List<BaseDbAdapter> databases, {
    SearchFilterObject? storyFilter,
    int? year,
  }) async {
    Map<String, CollectionDbModel<BaseDbModel>> tables = {};

    bool isGlobalBucket = year == BackupFileObject.kGlobalBackupYear;
    bool isYearlyBucket = year != null && !isGlobalBucket;

    for (BaseDbAdapter db in databases) {
      // year == null means "full export/legacy backup" — include every table
      // unfiltered, same as before. Otherwise route each table to whichever single
      // bucket it belongs to: non-year-partitioned tables (tags, templates, ...) only
      // ever go in the global bucket, in full; year-partitioned tables only ever go
      // in their real year's bucket, filtered by createdAt.year.
      if (isGlobalBucket && db.isYearPartitioned) continue;
      if (isYearlyBucket && !db.isYearPartitioned) continue;

      Map<String, dynamic>? filters = isYearlyBucket ? {'created_year': year} : null;

      if (db.tableName == StoryDbModel.db.tableName && storyFilter != null) {
        filters ??= storyFilter.toDatabaseFilter();
      }

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
