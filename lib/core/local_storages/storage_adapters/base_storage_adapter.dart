import 'dart:convert';
import 'package:flutter/foundation.dart';

abstract class BaseStorageAdapter<T> {
  Future<void> remove({required String key});
  Future<String?> readStr({required String key});
  Future<void> writeStr({required String key, required String value});

  T? validateResult(dynamic data) {
    if (data is T) return data;
    return null;
  }

  Future<T?> read({required String key}) async {
    try {
      String? value = await readStr(key: key);

      if (value != null) {
        Map decoded = jsonDecode(value);
        dynamic data = decoded['data'];
        return validateResult(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print("ERROR: read $e");
      }
      await remove(key: key);
      return null;
    }
  }

  Future<void> write({
    required String key,
    required T value,
  }) {
    String encoded = jsonEncode({"data": value});
    return writeStr(key: key, value: encoded);
  }
}
