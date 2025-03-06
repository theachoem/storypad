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
  }
}
