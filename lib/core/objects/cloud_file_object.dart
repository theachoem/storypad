import 'package:googleapis/drive/v3.dart' as drive;
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

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

  /// [remotePath] is the file's full WebDAV path — used as [id] since Nextcloud
  /// has no separate stable file-ID concept exposed over plain WebDAV.
  factory CloudFileObject.fromNextcloud(
    webdav.File file, {
    required String remotePath,
    bool trashed = false,
  }) {
    return CloudFileObject(
      fileName: file.name,
      id: remotePath,
      description: null,
      sizeInBytes: file.size,
      createdAt: file.cTime,
      modifiedAt: file.mTime,
      trashed: trashed,
    );
  }

  /// [remotePath] is the file's path relative to the app's private iCloud
  /// container data root — used as [id] since, like Nextcloud, ubiquity
  /// containers have no separate stable file-ID concept. [file] is the
  /// metadata dictionary returned by the native `ICloudBackupService`.
  factory CloudFileObject.fromICloud(
    Map<Object?, Object?> file, {
    required String remotePath,
    bool trashed = false,
  }) {
    DateTime? epochSecondsToDateTime(Object? value) {
      if (value is num) return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
      return null;
    }

    return CloudFileObject(
      fileName: file['name'] as String?,
      id: remotePath,
      description: null,
      sizeInBytes: file['sizeInBytes'] as int?,
      createdAt: epochSecondsToDateTime(file['createdAt']),
      modifiedAt: epochSecondsToDateTime(file['modifiedAt']),
      trashed: trashed,
    );
  }

  /// [file] is the decoded JSON metadata object Dropbox returns from
  /// `files/upload`, `files/get_metadata`, `files/list_folder`, etc. Unlike
  /// Nextcloud/iCloud, Dropbox assigns a real stable file ID (`id:xxxx`)
  /// independent of path — that ID is used as [id] here, not the path.
  factory CloudFileObject.fromDropbox(Map<String, dynamic> file, {bool trashed = false, String? idOverride}) {
    return CloudFileObject(
      fileName: file['name'] as String?,
      // Deleted-file metadata (`.tag == 'deleted'`) carries no `id` field at
      // all (only live FileMetadata does) — callers resolving a possibly-
      // trashed file pass the already-known query key as [idOverride].
      id: idOverride ?? file['id'] as String,
      description: null,
      sizeInBytes: file['size'] as int?,
      createdAt: DateTime.tryParse(file['client_modified'] as String? ?? ''),
      modifiedAt: DateTime.tryParse(file['server_modified'] as String? ?? ''),
      trashed: trashed,
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
