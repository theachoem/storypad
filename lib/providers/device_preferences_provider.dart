import 'package:flutter/material.dart'
    show Brightness, BuildContext, ChangeNotifier, Color, FontWeight, ThemeMode, View;
import 'package:storypad/core/constants/app_constants.dart' show kDefaultFontWeight;
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart' show AnalyticsUserProperyService;
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';

class DevicePreferencesProvider extends ChangeNotifier {
  static DevicePreferencesStorage get storage => DevicePreferencesStorage.appInstance;

  DevicePreferencesObject _preferences = storage.preferences;
  DevicePreferencesObject get preferences => _preferences;
  ThemeMode get themeMode => preferences.themeMode;

  // Sometimes reading `ColorScheme.of(context).brightness` may not reflect the correct dark mode state,
  // especially if the widget hasn't rebuilt yet after a system theme change.
  // In such cases, we determine dark mode based directly on ThemeMode and platform brightness.
  bool isDarkModeBaseOnThemeMode(BuildContext context) {
    if (themeMode == ThemeMode.system) {
      return View.maybeOf(context)?.platformDispatcher.platformBrightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }

  void reset() {
    _preferences = DevicePreferencesObject.initial();
    storage.remove();
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFontFamily(newFontFamily: _preferences.fontFamily);
    AnalyticsUserProperyService.instance.logSetColorSeedTheme(newColor: null);
    AnalyticsUserProperyService.instance.logSetThemeMode(newThemeMode: ThemeMode.system);
    AnalyticsUserProperyService.instance.logSetFontWeight(newFontWeight: kDefaultFontWeight);
  }

  void setColorSeed(Color color) {
    _preferences = _preferences.copyWith(
      // ignore: deprecated_member_use
      colorSeedValue: _preferences.colorSeedValue == color.value ? null : color.value,
    );

    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetColorSeedTheme(
      newColor: _preferences.colorSeed,
    );
  }

  void setThemeMode(ThemeMode? value) {
    if (value != null && value != themeMode) {
      _preferences = _preferences.copyWith(themeMode: value);
      storage.writeObject(_preferences);
      notifyListeners();

      AnalyticsUserProperyService.instance.logSetThemeMode(
        newThemeMode: value,
      );
    }
  }

  void setFontWeight(FontWeight fontWeight) {
    _preferences = _preferences.copyWith(fontWeightIndex: fontWeight.index);
    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFontWeight(
      newFontWeight: fontWeight,
    );
  }

  void setFontFamily(String fontFamily) {
    _preferences = _preferences.copyWith(fontFamily: fontFamily);
    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFontFamily(
      newFontFamily: fontFamily,
    );
  }

  void setFontSize(FontSizeOption? fontSize) {
    _preferences = _preferences.copyWith(fontSize: fontSize);
    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFontSize(
      newFontSize: fontSize,
    );
  }

  void setTimeFormat(TimeFormatOption timeFormat) {
    _preferences = _preferences.copyWith(timeFormat: timeFormat);
    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetTimeFormat(
      timeFormat: timeFormat,
    );
  }

  void toggleThemeMode(
    BuildContext context, {
    Duration? delay,
  }) async {
    if (themeMode == ThemeMode.system) {
      Brightness? brightness = View.maybeOf(context)?.platformDispatcher.platformBrightness;
      bool isDarkMode = brightness == Brightness.dark;

      if (delay != null) await Future.delayed(delay, () {});
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
    } else {
      bool isDarkMode = themeMode == ThemeMode.dark;

      if (delay != null) await Future.delayed(delay, () {});
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
    }
  }
}
