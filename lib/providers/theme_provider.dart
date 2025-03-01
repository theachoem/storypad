import 'package:flutter/material.dart';
import 'package:storypad/core/objects/theme_object.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart';
import 'package:storypad/core/storages/theme_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static ThemeStorage get storage => ThemeStorage.instance;

  ThemeObject _theme = storage.theme;
  ThemeObject get theme => _theme;
  ThemeMode get themeMode => theme.themeMode;

  void setColorSeed(Color color) {
    _theme = _theme.copyWithNewColor(color, removeIfSame: true);
    storage.writeObject(_theme);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetColorSeedTheme(
      newColor: _theme.colorSeed,
    );
  }

  void setThemeMode(ThemeMode? value) {
    if (value != null && value != themeMode) {
      _theme = _theme.copyWith(themeMode: value);
      storage.writeObject(_theme);
      notifyListeners();

      AnalyticsUserProperyService.instance.logSetThemeMode(
        newThemeMode: value,
      );
    }
  }

  void setFontWeight(FontWeight fontWeight) {
    _theme = _theme.copyWith(fontWeight: fontWeight);
    storage.writeObject(_theme);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFontWeight(
      newFontWeight: fontWeight,
    );
  }

  void setFontFamily(String fontFamily) {
    _theme = _theme.copyWith(fontFamily: fontFamily);
    storage.writeObject(_theme);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFontFamily(
      newFontFamily: fontFamily,
    );
  }

  void toggleThemeMode(BuildContext context) {
    if (themeMode == ThemeMode.system) {
      Brightness? brightness = View.of(context).platformDispatcher.platformBrightness;
      bool isDarkMode = brightness == Brightness.dark;
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
    } else {
      bool isDarkMode = themeMode == ThemeMode.dark;
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
    }
  }

  bool isDarkMode(BuildContext context) {
    if (themeMode == ThemeMode.system) {
      Brightness? brightness = View.of(context).platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }
}
