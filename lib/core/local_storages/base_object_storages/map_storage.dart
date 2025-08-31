import 'dart:convert';
import 'package:storypad/core/local_storages/preference_storages/default_storage.dart';

abstract class MapStorage extends DefaultStorage<String> {
  Future<Map<String, dynamic>?> readMap() async {
    String? result = await read();
    if (result != null) return jsonDecode(result);
    return null;
  }

  Future<void> writeMap(Map<String, dynamic> map) async {
    return write(jsonEncode(map));
  }

  Future<P?> getValue<P>(String key) async {
    final map = await readMap();
    return map?[key] is P ? (map?[key]) : null;
  }

  Future<void> setValue(String key, dynamic value) async {
    return readMap().then((map) {
      map ??= {};
      map[key] = value;
      return writeMap(map);
    });
  }

  Future<void> removeValue(String key) async {
    return readMap().then((map) {
      map ??= {};
      map.remove(key);
      return writeMap(map);
    });
  }
}
