import 'dart:io';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/asset_file_matcher_service.dart';
import 'package:storypad/core/storages/base_object_storages/bool_storage.dart';

class _RanAssetOrphanedFixerStorage extends BoolStorage {}

/// Fixes orphaned assets by matching temp files to database entries.
///
/// Orphaned assets have no local file and no cloud backup.
/// Runs on app startup to reconnect assets with their files in /tmp.
class AssetOrphanedFixerService {
  Future<void> call() async {
    if (await _RanAssetOrphanedFixerStorage().read() == true) return;
    _RanAssetOrphanedFixerStorage().write(true);

    final tmpDir = Directory('${kSupportDirectory.path}/tmp');

    if (!tmpDir.existsSync()) return AppLogger.d('❌ /tmp directory does not exist');

    var assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);
    var orphanedAssets = assets.where((asset) => asset.cloudDestinations.isEmpty && asset.localFile == null).toList();
    if (orphanedAssets.isEmpty) return AppLogger.d('✅ No orphaned assets found');
    AppLogger.d('🔍 Found ${orphanedAssets.length} orphaned assets');

    final availableFiles = tmpDir.listSync().whereType<File>().where((f) => f.path.endsWith('.m4a')).toList();
    AppLogger.d('📁 Found ${availableFiles.length} files in tmp directory');

    int matchedCount = 0;
    int failedCount = 0;

    final filesByAssets = await AssetFileMatcherService.matchAssets(
      assets: orphanedAssets,
      availableFiles: availableFiles,
    );

    for (final entry in filesByAssets.entries) {
      AppLogger.d('🔗 Matched asset ${entry.key.id} with file ${entry.value.path}');

      final asset = entry.key;
      final matchedFile = entry.value;

      final destinationPath = asset.localFilePath;
      final destinationFile = File(destinationPath);

      await destinationFile.create(recursive: true);
      await destinationFile.writeAsBytes(await matchedFile.readAsBytes());
      await matchedFile.delete();
      await asset.save();

      matchedCount++;
    }

    AppLogger.d('✅ Matched $matchedCount assets');
    AppLogger.d('❌ Failed to match $failedCount assets');
  }
}
