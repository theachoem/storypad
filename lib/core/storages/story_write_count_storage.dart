import 'package:storypad/core/storages/base_object_storages/integer_storage.dart';

class StoryWriteCountStorage extends IntegerStorage {
  Future<int> increment() async {
    final current = await read() ?? 0;
    final next = current + 1;
    await write(next);
    return next;
  }
}
