import 'package:storypad/core/storages/theme_storage.dart';

class ThemeInitializer {
  static Future<void> call() async {
    await ThemeStorage.instance.load();
  }
}
