import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/font_weight_extension.dart';
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';

class DevicePreferencesProvider extends ChangeNotifier with WidgetsBindingObserver {
  static DevicePreferencesStorage get storage => DevicePreferencesStorage.appInstance;

  DevicePreferencesObject _preferences = storage.preferences;
  DevicePreferencesObject get preferences => _preferences;
  ThemeMode get themeMode => preferences.themeMode;

  final Map<String, List<void Function()>> _listeners = {};

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
    _preferences = _preferences.copyWith(fontWeightIndex: fontWeight.weightIndex);
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

  void addListenerForVoicePlaybackSpeed(void Function() listener) {
    _listeners['voice_playback_speed'] ??= [];
    _listeners['voice_playback_speed']!.add(listener);
  }

  void removeListenerForVoicePlaybackSpeed(void Function() listener) {
    _listeners['voice_playback_speed']?.remove(listener);
  }

  // no need to notifyListeners as it will refresh the whole app UI
  // but we do need to notify specific listeners for voice playback speed changes
  void setVoicePlaybackSpeed(double speed) {
    _preferences = _preferences.copyWith(voicePlaybackSpeed: speed);
    storage.writeObject(_preferences);

    _listeners['voice_playback_speed']?.forEach((listener) => listener());
  }

  Future<void> toggleThemeMode(
    BuildContext context, {
    Duration? delay,
  }) async {
    if (delay != null) await Future.delayed(delay, () {});
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      Brightness? brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }

  DevicePreferencesProvider() {
    WidgetsBinding.instance.addObserver(this);

    _setPlatformTheme();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();

    _setPlatformTheme();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    _setPlatformTheme();
  }

  void _setPlatformTheme() {
    if (Platform.isMacOS) {
      WindowManipulator.overrideMacOSBrightness(dark: isDarkMode);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
