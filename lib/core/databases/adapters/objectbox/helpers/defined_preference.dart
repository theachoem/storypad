part of '../preferences_box.dart';

class _DefinedPreference {
  final int id;
  final String key;

  _DefinedPreference({
    required this.id,
    required this.key,
  });

  String? get() {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    return record?.value;
  }

  void set(String value) {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    if (record?.value.trim() == value.trim()) return;

    PreferencesBox().box.put(
      PreferenceObjectBox(
        id: id,
        key: key,
        value: value.trim(),
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
