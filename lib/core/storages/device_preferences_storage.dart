// ignore_for_file: deprecated_member_use_from_same_package

import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';
import 'package:storypad/core/storages/theme_storage.dart';

class DevicePreferencesStorage extends ObjectStorage<DevicePreferencesObject> {
  static DevicePreferencesStorage appInstance = DevicePreferencesStorage();

  DevicePreferencesObject get preferences => _preferences ?? DevicePreferencesObject.initial();
  DevicePreferencesObject? _preferences;

  Future<void> load() async {
    final legacyData = await ThemeStorage().readObject();
    if (legacyData != null) {
      ThemeStorage().remove();
      DevicePreferencesObject newData = DevicePreferencesObject.initial().copyWith(
        fontFamily: legacyData.fontFamily,
        fontWeightIndex: legacyData.fontWeight.index,
        themeMode: legacyData.themeMode,
        // ignore: deprecated_member_use
        colorSeedValue: legacyData.colorSeed?.value,
      );
      await writeObject(newData);
    }

    _preferences = await readObject();
    if (_preferences == null) {
      // ignore: deprecated_member_use
      _preferences = DevicePreferencesObject(colorSeedValue: kDefaultColorSeed.value);
      await writeObject(_preferences!);
    }
  }

  @override
  DevicePreferencesObject decode(Map<String, dynamic> json) => DevicePreferencesObject.fromJson(json);

  @override
  Map<String, dynamic> encode(DevicePreferencesObject object) => object.toJson();
}
