import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class CloudFileObject {
  final String? fileName;
  final String id;
  final String? description;
  final int? sizeInBytes;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool? trashed;

  CloudFileObject({
    required this.fileName,
    required this.id,
    required this.description,
    this.sizeInBytes,
    this.createdAt,
    this.modifiedAt,
    this.trashed,
  });

  factory CloudFileObject.fromGoogleDrive(drive.File file) {
    return CloudFileObject(
      fileName: file.name,
      id: file.id!,
      description: file.description,
      sizeInBytes: file.size != null ? int.tryParse(file.size.toString()) : null,
      createdAt: file.createdTime,
      modifiedAt: file.modifiedTime,
      trashed: file.trashed,
    );
  }

  factory CloudFileObject.fromLegacyStoryPad(drive.File file) {
    return CloudFileObject(
      fileName: file.name,
      id: file.id!,
      description: file.description,
    );
  }

  bool? get hasCompression => getFileInfo()?.hasCompression;
  int? get year => getFileInfo()?.year;
  DateTime? get lastUpdatedAt => getFileInfo()?.createdAt; // For v3, createdAt is actually the lastUpdatedAt timestamp

  // story2025-01-20 21:31:05.234761.zip
  BackupFileObject? getFileInfo() {
    if (fileName == null) return null;

    if (fileName?.startsWith("story") == true) {
      String createdAtStr = fileName!.replaceAll("story", "").replaceAll(".zip", "");
      DateTime? createdAt = DateTime.tryParse(createdAtStr);

      return BackupFileObject(
        createdAt: createdAt!,
        device: DeviceInfoObject(model: 'StoryPad', id: 'legacy-model-id'),
        hasCompression: fileName!.endsWith('.zip'),
      );
    } else {
      return BackupFileObject.fromFileName(fileName!);
    }
  }
}
