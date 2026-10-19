import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';

class BackupObject {
  final Map<String, dynamic> tables;
  final BackupFileObject fileInfo;

  final int version;
  final int? year; // For v3 yearly backups - indicates which year this backup contains

  int? originalFileSize;

  // BackupObject version is different from BackupFileObject version.
  // they serve different purpose.
  //
  // v2 stores the tables under `data` instead of `tables`, so an app from before Markdown pages -- which reads
  // `tables` -- rejects the file ("empty or invalid") instead of restoring its stories as empty pages.
  static const int currentVersion = 2;

  BackupObject({
    required this.tables,
    required this.fileInfo,
    this.version = currentVersion,
    this.year,
  });

  static BackupObject fromContents(Map<String, dynamic> contents) {
    final version = int.tryParse(contents['version'].toString()) ?? currentVersion;
    final year = contents['year'] != null ? int.tryParse(contents['year'].toString()) : null;
    return BackupObject(
      version: version,
      tables: contents['data'] ?? contents['tables'],
      year: year,
      fileInfo: BackupFileObject(
        // The file version the contents came from: v2 contents are only written to v4 yearly files, v1 contents to v3
        // yearly files (or, without a year, to the legacy v1/v2 files -- the default).
        version: year == null ? null : (version >= 2 ? BackupFileObject.currentYearlyVersion : '3'),
        createdAt: DateTime.parse(contents['meta_data']['created_at']),
        device: DeviceInfoObject(
          model: contents['meta_data']['device_model'],
          id: contents['meta_data']['device_id'],
        ),
        year: year,
        hasCompression: false,
      ),
    );
  }

  Map<String, dynamic> toContents() {
    final contents = {
      'version': version,
      version >= 2 ? 'data' : 'tables': tables,
      'meta_data': {
        'device_model': fileInfo.device.model,
        'device_id': fileInfo.device.id,
        'created_at': fileInfo.createdAt.toIso8601String(),
      },
    };

    if (year != null) {
      contents['year'] = year!;
    }

    return contents;
  }
}
