import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

/// A cloud service's yearly backup files, newest per year, by generation.
class YearlyBackupFilesObject {
  const YearlyBackupFilesObject({this.current = const {}, this.legacy = const {}});

  /// Files in the format this app writes ([BackupFileObject.currentYearlyVersion]): what's synced, compared and
  /// updated.
  final Map<int, CloudFileObject> current;

  /// v3 files -- or, on a service without any yearly file, its newest single-file v2/v1 backup under year `-1` --
  /// written by apps from before Markdown pages. Never updated; imported once for a year without a [current] file.
  final Map<int, CloudFileObject> legacy;

  /// Every year's newest file, current ones winning -- e.g. for browsing backups.
  Map<int, CloudFileObject> get merged => {...legacy, ...current};

  /// Legacy files for years without a current file: the ones to import.
  Map<int, CloudFileObject> get legacyOnly => {
    for (final entry in legacy.entries)
      if (!current.containsKey(entry.key)) entry.key: entry.value,
  };

  /// Sorts yearly backup [files] (any version, e.g. a folder listing) into generations, keeping the newest file per
  /// year; files of other versions (e.g. from a newer app) and non-backup files are ignored.
  factory YearlyBackupFilesObject.fromFiles(Iterable<CloudFileObject> files) {
    final current = <int, CloudFileObject>{};
    final legacy = <int, CloudFileObject>{};
    for (final file in files) {
      final year = file.year;
      if (year == null) continue;

      final target = switch (file.version) {
        BackupFileObject.currentYearlyVersion => current,
        '3' => legacy,
        _ => null,
      };
      if (target == null) continue;

      // When duplicates exist for the same year, keep the one with the newest filename timestamp. This prevents
      // non-deterministic ordering from causing endless re-uploads when multiple files exist for a year.
      final existing = target[year];
      final existingTs = existing?.lastUpdatedAt;
      final newTs = file.lastUpdatedAt;
      final isNewer = existing == null || (newTs != null && (existingTs == null || newTs.isAfter(existingTs)));
      if (isNewer) target[year] = file;
    }
    return YearlyBackupFilesObject(current: current, legacy: legacy);
  }
}
