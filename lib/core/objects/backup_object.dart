import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class BackupObject {
  final Map<String, dynamic> tables;
  final BackupFileObject fileInfo;

  BackupObject({
    required this.tables,
    required this.fileInfo,
  });

  static BackupObject fromContents(Map<String, dynamic> contents) {
    return BackupObject(
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

  Map<String, Map<String, dynamic>> toContents() {
    return {
      'tables': tables,
      'meta_data': {
        'device_model': fileInfo.device.model,
        'device_id': fileInfo.device.id,
        'created_at': fileInfo.createdAt.toIso8601String(),
      }
    };
  }
}
