// ignore_for_file: constant_identifier_names

import 'package:storypad/core/storages/base_object_storages/map_storage.dart';
import 'package:storypad/core/types/new_badge.dart';

class NewBadgeStorage extends MapStorage {
  Future<bool> clicked(String badge) async {
    return readMap().then((e) => e?[badge] == true);
  }

  Future<void> click(String badge) async {
    Map<String, dynamic> result = await readMap() ?? {};
    result.removeWhere((e, value) => !NewBadge.keys.contains((e)));
    result[badge] = true;
    return writeMap(result);
  }
}
