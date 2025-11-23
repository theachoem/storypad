import 'dart:io';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
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
  }

  // The 'tags' column was newly added to the asset table, so existing data may be missing tags.
  // This method runs exactly once to populate initial tag data for assets.
  static Future<void> computeStoryTagsForAsset() async {
    bool initialComputed = await ComputedInitialTagsForAssetsStorage().read() ?? false;

    if (initialComputed == false) {
      debugPrint('$DatabaseInitializer.computeStoryTagsForAsset initialComputed: $initialComputed');

      var assets = await AssetDbModel.db.where().then((e) => e?.items ?? <AssetDbModel>[]);
      for (int i = 0; i < assets.length; i++) {
        var tags = await StoryDbModel.db.computeStoriesTagsForAsset(assets[i]);
        final isLastAsset = i == assets.length - 1;
        await assets[i].copyWith(tags: tags.toList()).save(runCallbacks: isLastAsset);
      }

      await ComputedInitialTagsForAssetsStorage().write(true);
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
