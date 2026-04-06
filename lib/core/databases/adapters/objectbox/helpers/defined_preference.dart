part of '../preferences_box.dart';

class _DefinedPreference<T> {
  final int id;
  final String key;

  _DefinedPreference({
    required this.id,
    required this.key,
  });

  T? get() {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    if (record == null) return null;

    if (T == bool) {
      if (record.value.trim().toLowerCase() == "true") return true as T;
      if (record.value.trim().toLowerCase() == "false") return false as T;
      return null;
    } else if (T == int) {
      return int.tryParse(record.value.trim()) as T?;
    } else if (T == double) {
      return double.tryParse(record.value.trim()) as T?;
    } else if (T == String) {
      return record.value.trim() as T?;
    } else if (T == DateTime) {
      int? timestamp = int.tryParse(record.value.trim());
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp) as T?;
    }

    return null;
  }

  void set(T value) {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);

    String stringValue;

    if (T == bool) {
      stringValue = value.toString();
    } else if (T == int || T == double) {
      stringValue = value.toString();
    } else if (T == String) {
      stringValue = value as String;
    } else if (T == DateTime) {
      stringValue = (value as DateTime).millisecondsSinceEpoch.toString();
    } else {
      throw Exception("Unsupported type");
    }

    if (record?.value.trim() == stringValue.trim()) return;

    PreferencesBox().box.put(
      PreferenceObjectBox(
        id: id,
        key: key,
        value: stringValue,
        createdAt: record?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void touch() {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    PreferencesBox().box.put(
      PreferenceObjectBox(
        id: id,
        key: key,
        value: DateTime.now().toIso8601String(),
        createdAt: record?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
