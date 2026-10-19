import 'package:storypad/core/storages/base_object_storages/string_storage.dart';

/// When this device last saw an app from before Markdown pages upload a backup: the server time of the newest legacy
/// (v3) file that was newer than its year's current file (see `BackupLatestCheckerService.olderAppUploadedAtOf`).
///
/// That app never learns of deletions made here. While it was seen recently, deleted records are kept past their
/// usual 30 days (`BaseBox.cleanupOldDeletedRecords`), so its copy of a story deleted here can't come back once it
/// updates.
///
/// TODO: remove once no device runs an app before 2.34.0, the first to write v4 backups -- e.g. when Data & Backup
/// stops naming devices still writing v3 files (`BackupProvider.olderAppDeviceModels`). Remove together: this storage
/// and its uses in `BackupLatestCheckerService` and `BaseBox.cleanupOldDeletedRecords`, `OlderAppAssetIdsService` and
/// its use in `CloudOptimizeViewModel`, their tests, and the notes in docs/app/architecture/backup-sync.md.
class OlderAppLastSeenStorage extends StringStorage {
  static const keepDeletedRecordsFor = Duration(days: 90);

  Future<DateTime?> readDate() async => DateTime.tryParse(await read() ?? '');

  /// Keeps the newest time seen.
  Future<void> recordSeen(DateTime seenAt) async {
    final last = await readDate();
    if (last != null && !seenAt.isAfter(last)) return;
    await write(seenAt.toUtc().toIso8601String());
  }

  Future<bool> seenWithin(Duration duration) async {
    final last = await readDate();
    return last != null && DateTime.now().difference(last) < duration;
  }
}
