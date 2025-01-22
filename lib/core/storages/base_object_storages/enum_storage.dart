import 'package:storypad/core/storages/preference_storages/default_storage.dart';

abstract class EnumStorage<T> extends DefaultStorage<String> {
  List<T> get values;

  Future<void> writeEnum(T value) async {
    (await adapter).write(key: key, value: "$value");
  }

  Future<T?> readEnum() async {
    String? result = await (await adapter).read(key: key);
    for (T e in values) {
      if ("$e" == result) return e;
    }
    return null;
  }

  T? fromString(String? element) {
    if (element == null) return null;

    for (T value in values) {
      // SortType.oldToNew, oldToNew
      if (value.toString().endsWith(element)) {
        return value;
      }
    }
    return null;
  }
}
