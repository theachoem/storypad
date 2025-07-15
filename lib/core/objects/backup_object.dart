import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class BackupObject {
  final Map<String, dynamic> tables;
  final BackupFileObject fileInfo;

  final int version;

  int? originalFileSize;

  // BackupObject version is different from BackupFileObject version.
  // they serve different purpose.
  static const int currentVersion = 1;

  BackupObject({
    required this.tables,
    required this.fileInfo,
    this.version = currentVersion,
  });

  static BackupObject fromContents(Map<String, dynamic> contents) {
    return BackupObject(
      version: int.tryParse(contents['version'].toString()) ?? currentVersion,
      tables: contents['tables'],
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
      'meta_data': {
        'device_model': fileInfo.device.model,
        'device_id': fileInfo.device.id,
        'created_at': fileInfo.createdAt.toIso8601String(),
      }
    };
  }
}
