import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/storages/backup_global_bucket_migration_storage.dart';

class BackupGlobalBucketMigrationInitializer {
  // TODO: remove this one-time migration once we're confident it has run on
  // every active install (see plans/2026-09-12-backup-global-nonyearly-tables/
  // and docs/app/architecture/backup-sync.md) — it only needs to run once per
  // year that already existed when the non-yearly-table backup split shipped.
  static Future<void> call() async {
    final storage = BackupGlobalBucketMigrationStorage();
    if (await storage.read() == true) return;

    final years = <int>{
      ...(await StoryDbModel.db.getLastUpdatedAtByYear()).keys,
      ...(await AssetDbModel.db.getLastUpdatedAtByYear()).keys,
      ...(await EventDbModel.db.getLastUpdatedAtByYear()).keys,
    };

    years.remove(DateTime.now().year);

    for (final year in years) {
      final now = DateTime.now();

      await EventDbModel(
        id: now.millisecondsSinceEpoch + year,
        year: year,
        month: 1,
        day: 1,
        eventType: 'global_bucket_migration',
        createdAt: DateTime(year, 1, 1),
        updatedAt: now,
      ).createIfNotExist();
    }

    await storage.write(true);
  }
}
