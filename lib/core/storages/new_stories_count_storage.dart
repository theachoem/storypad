import 'package:storypad/core/storages/base_object_storages/integer_storage.dart';

class NewStoriesCountStorage extends IntegerStorage {
  Future<int> increase() async {
    int count = await read() ?? 0;
    count++;
    await write(count);
    return count;
  }
}
