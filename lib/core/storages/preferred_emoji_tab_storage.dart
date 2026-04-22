import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:storypad/core/storages/base_object_storages/map_storage.dart';

class PreferredEmojiTabStorage extends MapStorage {
  Future<Category?> getCategoryFor(int categoryId) {
    return readMap().then((map) {
      var result = map ?? {};
      if (result.containsKey(categoryId.toString())) {
        return Category.values.firstWhere((c) => c.name == result[categoryId.toString()]);
      } else {
        return null;
      }
    });
  }

  Future<void> setCategoryFor(int categoryId, Category? category) {
    return readMap().then((map) {
      var result = map ?? {};
      if (category != null) {
        result[categoryId.toString()] = category.name;
      } else {
        result.remove(categoryId.toString());
      }
      return writeMap(result);
    });
  }
}
