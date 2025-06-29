// ignore_for_file: constant_identifier_names

import 'package:storypad/core/storages/base_object_storages/map_storage.dart';
import 'package:storypad/core/types/new_badge.dart';

class NewBadgeStorage extends MapStorage {
  Future<bool> clicked(NewBadge badge) async {
    return readMap().then((e) => e?[badge.name] == true);
  }

  Future<void> click(NewBadge badge) async {
    Map<String, dynamic> result = await readMap() ?? {};
    result.removeWhere((e, value) => !NewBadge.keys.contains((e)));
    result[badge.name] = true;
    return writeMap(result);
  }
}
