import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class BackupObject {
  final Map<String, dynamic> tables;
  final BackupFileObject fileInfo;

  // { "table_name": {id: delete_at} }
  //
  // Example:
  // {
  //   "stories": {...},
  //   "tags": {...},
  // };
  final Map<String, Map<String, int>>? deletedRecords;
  final int version;

  int? originalFileSize;

  // BackupObject version is different from BackupFileObject version.
  // they serve different purpose.
  static const int currentVersion = 1;

  BackupObject({
    required this.tables,
    required this.deletedRecords,
    required this.fileInfo,
    this.version = currentVersion,
  });

  static BackupObject fromContents(Map<String, dynamic> contents) {
    Map<String, Map<String, int>>? deletedRecords;

    if (contents['deleted_records'] is Map) {
      deletedRecords = (contents['deleted_records'] as Map<dynamic, dynamic>?)?.map(
        (key, innerMap) => MapEntry(
          key.toString(),
          (innerMap as Map<dynamic, dynamic>).map(
            (k, v) => MapEntry(k.toString(), v as int),
          ),
        ),
      );
    }

    return BackupObject(
      version: int.tryParse(contents['version'].toString()) ?? currentVersion,
      tables: contents['tables'],
      deletedRecords: deletedRecords,
      fileInfo: BackupFileObject(
        createdAt: DateTime.parse(contents['meta_data']['created_at']),
        device: DeviceInfoObject(
          contents['meta_data']['device_model'],
          contents['meta_data']['device_id'],
        ),
      ),
    );
  }

  Map<String, dynamic> toContents() {
    return {
      'version': version,
      'tables': tables,
      'deleted_records': deletedRecords,
      'meta_data': {
        'device_model': fileInfo.device.model,
        'device_id': fileInfo.device.id,
        'created_at': fileInfo.createdAt.toIso8601String(),
      }
    };
  }
}
