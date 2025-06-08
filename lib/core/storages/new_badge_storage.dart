import 'package:storypad/core/storages/base_object_storages/map_storage.dart';

class NewBadgeStorage extends MapStorage {
  final Set<String> _badges = {"community_tile"};

  Future<bool> communityTileClicked() async {
    return readMap().then((e) => e?['community_tile'] == true);
  }

  Future<void> clickCommuntityTile() async {
    Map<String, dynamic> result = await readMap() ?? {};
    result.removeWhere((e, value) => !_badges.contains((e)));
    result['community_tile'] = true;
    return writeMap(result);
  }
}
