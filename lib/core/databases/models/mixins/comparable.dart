import 'dart:convert';
import 'package:storypad/core/databases/models/base_db_model.dart';

mixin Comparable<T extends BaseDbModel> on BaseDbModel {
  bool hasChanges(T other) {
    return keepComparableKeys(toJson()).hashCode != keepComparableKeys(other.toJson()).hashCode;
  }

  String keepComparableKeys(Map<String, dynamic> json) {
    json.removeWhere((key, value) {
      if (includeCompareKeys != null) {
        return excludeCompareKeys.contains(key) && !includeCompareKeys!.contains(key);
      } else {
        return excludeCompareKeys.contains(key);
      }
    });
    return jsonEncode(json);
  }

  List<String> get excludeCompareKeys;
  List<String>? get includeCompareKeys => null;
}
