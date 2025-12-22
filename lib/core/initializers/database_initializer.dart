import 'dart:io';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/services/asset_orphaned_fixer_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/storages/computed_initial_tags_for_assets_storage.dart';

class DatabaseInitializer {
  static Future<void> call() async {
    await StoryDbModel.db.initilize();
    await TagDbModel.db.initilize();

    await TemplateDbModel.db.initilize();
    await PreferenceDbModel.db.initilize();
    await AssetDbModel.db.initilize();
    await RelaxSoundMixModel.db.initilize();
    await EventDbModel.db.initilize();

    await migrateData();
  }

  static Future<void> migrateData() async {
    await StoryDbModel.db.migrateDataToV2();
    await moveExistingAssetToSupportDirectory();
    await computeStoryTagsForAsset();
    await migrateEmbedAssetsToUseRelativeFilePaths();
    await AssetOrphanedFixerService().call();
  }

  // The 'tags' column was newly added to the asset table, so existing data may be missing tags.
  // This method runs exactly once to populate initial tag data for assets.
  static Future<void> computeStoryTagsForAsset() async {
    bool initialComputed = await ComputedInitialTagsForAssetsStorage().read() ?? false;

    if (initialComputed == false) {
      AppLogger.d('$DatabaseInitializer.computeStoryTagsForAsset initialComputed: $initialComputed');

      var assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);
      for (int i = 0; i < assets.length; i++) {
        var tags = await StoryDbModel.db.computeStoriesTagsForAsset(assets[i]);
        final isLastAsset = i == assets.length - 1;
        await assets[i].copyWith(tags: tags.toList(), updatedAt: DateTime.now()).save(runCallbacks: isLastAsset);
      }

      await ComputedInitialTagsForAssetsStorage().write(true);
    }
  }

  // With the new asset embedding approach, we can export and import stories more reliably.
  static Future<void> migrateEmbedAssetsToUseRelativeFilePaths() async {
    var assets = await AssetDbModel.db.where(filters: {'version': 1}).then((e) => e?.items ?? <AssetDbModel>[]);

    for (int i = 0; i < assets.length; i++) {
      AssetDbModel asset = assets[i];
      final result = await StoryDbModel.db
          .buildQuery(filters: {'asset': asset.id}, returnDeleted: false)
          .build()
          .findAsync();

      /// URI link for embedding in Quill editor
      /// Automatically routes to correct scheme based on asset type:
      /// - Audio: storypad://audio/{id}
      /// - Image (or null): storypad://assets/{id}
      final legacyEmbedLink = switch (asset.type) {
        .image => 'storypad://assets/${asset.id}',
        .audio => 'storypad://audio/${asset.id}',
      };

      for (int j = 0; j < result.length; j++) {
        result[j].draftContent = result[j].draftContent?.replaceAll(legacyEmbedLink, asset.relativeLocalFilePath);
        result[j].latestContent = result[j].latestContent?.replaceAll(legacyEmbedLink, asset.relativeLocalFilePath);
      }

      asset = asset.copyWith(version: 2, originalSource: asset.relativeLocalFilePath);
      await StoryDbModel.db.box.putManyAsync(result);
      await AssetDbModel.db.set(asset, runCallbacks: false);
    }
  }

  static Future<void> moveExistingAssetToSupportDirectory() async {
    if (Directory("${kApplicationDirectory.path}/images").existsSync()) {
      for (final image in Directory("${kApplicationDirectory.path}/images").listSync()) {
        final destinationFile = File(image.path.replaceAll(kApplicationDirectory.path, kSupportDirectory.path));
        if (!await destinationFile.parent.exists()) await destinationFile.create(recursive: true);
        await destinationFile.writeAsBytes(await File(image.path).readAsBytes());
        await image.delete(recursive: true);
      }

      await Directory("${kApplicationDirectory.path}/images").delete(recursive: true);
      final items = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);

      for (final asset in items) {
        await AssetDbModel.db.set(
          runCallbacks: false,
          asset.copyWith(
            originalSource: asset.originalSource.replaceAll(kApplicationDirectory.path, kSupportDirectory.path),
          ),
        );
      }
    }
  }
}
