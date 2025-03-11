import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharePreferencesStorageAdapter<T> extends BaseStorageAdapter<T> {
  Future<SharedPreferences> get _instance => SharedPreferences.getInstance();
  SharedPreferences? instance;

  @override
  Future<void> remove({required String key}) async {
    instance ??= await _instance;
    instance!.remove(key);
  }

  @override
  Future<String?> readStr({required String key}) async {
    instance ??= await _instance;
    return instance!.getString(key);
  }

  @override
  Future<void> writeStr({required String key, required String value}) async {
    instance ??= await _instance;
    await instance!.setString(key, value);
  }
}
