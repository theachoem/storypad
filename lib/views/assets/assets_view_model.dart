import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'assets_view.dart';

class AssetsViewModel extends BaseViewModel {
  final AssetsRoute params;

  AssetsViewModel({
    required this.params,
  }) {
    load();

    StoryDbModel.db.addGlobalListener(() async {
      load();
    });
  }

  Map<int, int> storiesCount = {};

  Future<void> load() async {
    CollectionDbModel<AssetDbModel>? assets = await AssetDbModel.db.where();
    for (var asset in assets?.items ?? <AssetDbModel>[]) {
      storiesCount[asset.id] = await StoryDbModel.db.count(filters: {
        'asset': asset.id,
      });
    }

    notifyListeners();
  }
}
