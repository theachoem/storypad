part of 'validator.dart';

String? shift(List<String> elements) {
  if (elements.isEmpty) return null;
  return elements.removeAt(0);
}

Map<String, Object> merge(
  Map<String, Object>? obj,
  Map<String, Object> defaults,
) {
  if (obj == null) {
    return defaults;
  }
  defaults.forEach((key, val) => obj.putIfAbsent(key, () => val));
  return obj;
}
