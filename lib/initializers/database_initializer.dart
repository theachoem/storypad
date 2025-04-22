import 'dart:io';

import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';

class DatabaseInitializer {
  static Future<void> call() async {
    await StoryDbModel.db.initilize();
    await TagDbModel.db.initilize();
    await PreferenceDbModel.db.initilize();
    await AssetDbModel.db.initilize();

    await migrateData();
  }

  static Future<void> migrateData() async {
    await StoryDbModel.db.migrateDataToV2();
    await moveExistingAssetToSupportDirectory();
  }

  static Future<void> moveExistingAssetToSupportDirectory() async {
    if (Directory("${kApplicationDirectory.path}/images").existsSync()) {
      for (final image in Directory("${kApplicationDirectory.path}/images").listSync()) {
        final destinationFile = File(image.path.replaceAll(kApplicationDirectory.path, kSupportDirectory.path));
        await destinationFile.writeAsBytes(await File(image.path).readAsBytes());
        await image.delete();
      }

      await Directory("${kApplicationDirectory.path}/images").delete();
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
