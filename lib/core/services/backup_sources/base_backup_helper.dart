part of 'base_backup_source.dart';

class _BaseBackupHelper {
  Future<BackupObject> constructBackup({
    required List<BaseDbAdapter<BaseDbModel>> databases,
    required DateTime lastUpdatedAt,
  }) async {
    debugPrint('_BaseBackupHelper#constructBackup');
    Map<String, dynamic> tables = await _constructTables(databases);
    debugPrint('_BaseBackupHelper#constructBackup ${tables.keys}');

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
    io.Directory root = await getApplicationSupportDirectory();
    io.Directory parent = io.Directory("${root.path}/${FilePathType.backups.name}");

    var file = io.File("${parent.path}/$cloudStorageId.json");
    if (!file.existsSync()) {
      await file.create(recursive: true);
      debugPrint('_BaseBackupHelper#constructFile createdFile: ${file.path.replaceAll(' ', '%20')}');
    }

    debugPrint('_BaseBackupHelper#constructFile encodingJson');
    String encodedJson = jsonEncode(backup.toContents());
    debugPrint('_BaseBackupHelper#constructFile encodedJson');

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
