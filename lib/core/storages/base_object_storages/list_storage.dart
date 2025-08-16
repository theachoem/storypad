import 'dart:convert';
import 'package:storypad/core/storages/preference_storages/default_storage.dart';

class ListStorage<T> extends DefaultStorage<String> {
  // only accept int, string, bool element
  void validation(T element) {
    assert(element is int || element is String || element is bool);
  }

  Future<void> writeList(List<T>? value) async {
    if (value?.isNotEmpty == true) validation(value!.first);
    return (await adapter).write(
      key: key,
      value: jsonEncode(value),
    );
  }

  Future<List<T>?> readList() async {
    String? result = await (await adapter).read(key: key);

    if (result != null) {
      dynamic decoded = jsonDecode(result);
      return toType(decoded);
    }

    return null;
  }

  List<T>? toType(dynamic decoded) {
    if (decoded is! List) return null;
    List<T> output = [];
    for (dynamic element in decoded) {
      if (element is T) output.add(element);
    }
    return output;
  }
}
