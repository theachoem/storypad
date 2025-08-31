import 'package:storypad/core/local_storages/device_preferences_storage.dart';

class ThemeInitializer {
  static Future<void> call() async {
    await DevicePreferencesStorage.appInstance.load();
  }
}
