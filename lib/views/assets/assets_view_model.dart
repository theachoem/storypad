import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'assets_view.dart';

class AssetsViewModel extends BaseViewModel {
  final AssetsRoute params;

  AssetsViewModel({
    required this.params,
  }) {
    load();
  }

  List<AssetDbModel>? assets;
  Map<int, int> storiesCount = {};

  Future<void> load() async {
    assets = await AssetDbModel.db.where().then((e) => e?.items ?? []);
    notifyListeners();

    for (var asset in assets!) {
      storiesCount[asset.id] = await StoryDbModel.db.count(filters: {
        'asset': asset.id,
      });
    }
  }
}
