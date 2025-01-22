import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';

class MemoryStorageAdapter<T> extends BaseStorageAdapter<T> {
  static Map<String, dynamic> map = {};

  @override
  Future<void> remove({required String key}) async {
    map.remove(key);
  }

  @override
  Future<String?> readStr({required String key}) async {
    return map[key];
  }

  @override
  Future<void> writeStr({required String key, required String value}) async {
    map[key] = value;
  }
}
