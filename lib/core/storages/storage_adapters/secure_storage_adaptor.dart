import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageAdaptor<T> extends BaseStorageAdapter<T> {
  final storage = const FlutterSecureStorage();

  @override
  Future<String?> readStr({
    required String key,
  }) {
    return storage.read(key: key);
  }

  @override
  Future<void> remove({
    required String key,
  }) {
    return storage.delete(key: key);
  }

  @override
  Future<void> writeStr({
    required String key,
    required String value,
  }) {
    return storage.write(
      key: key,
      value: value,
    );
  }
}
