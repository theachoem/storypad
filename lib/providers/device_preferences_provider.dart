import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/font_weight_extension.dart';
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/core/types/add_on_type.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';

class DevicePreferencesProvider extends ChangeNotifier with WidgetsBindingObserver {
  static DevicePreferencesStorage get storage => DevicePreferencesStorage.appInstance;

  DevicePreferencesObject _preferences = storage.preferences;
  DevicePreferencesObject get preferences => _preferences;
  ThemeMode get themeMode => preferences.themeMode;

  bool get enableRelaxSounds => preferences.enableRelaxSounds ?? false;
  bool enablePeriodCalendar(BuildContext context) =>
      preferences.enablePeriodCalendar ?? context.read<InAppPurchaseProvider>().periodCalendar;

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
    _preferences = DevicePreferencesObject.initial().copyWith(
      // Preserve add-on states as they are tied to purchases, not preferences.
      enableRelaxSounds: preferences.enableRelaxSounds,
      enablePeriodCalendar: preferences.enablePeriodCalendar,
    );

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

  void setFirstDayOfWeek(FirstDayOfWeekOption value) {
    _preferences = _preferences.copyWith(firstDayOfWeek: value);
    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetFirstDayOfWeek(
      firstDayOfWeek: value,
    );
  }

  void setStoryTilePreferences(StoryTilePreferencesObject preferences) {
    _preferences = _preferences.copyWith(storyTilePreferences: preferences);
    storage.writeObject(_preferences);
    notifyListeners();

    AnalyticsUserProperyService.instance.logSetStoryTilePreferences(
      showTime: preferences.showTime,
      showPageCount: preferences.showPageCount,
      showTagLabels: preferences.showTagLabels,
      showVoiceCount: preferences.showVoiceCount,
      displayCharacterCount: preferences.displayCharacterCount,
    );
  }

  // No need to notify listeners as it only used when create new story.
  void setDefaultStoryPreferences(DefaultStoryPreferencesObject preferences) {
    _preferences = _preferences.copyWith(defaultStoryPreferences: preferences);
    storage.writeObject(_preferences);

    AnalyticsUserProperyService.instance.logSetDefaultStoryPreferences(
      defaultLayoutType: preferences.defaultLayoutType.name,
      hasColorSeed: preferences.defaultColorSeedValue != null,
      hasBackground: preferences.defaultBackgroundImagePath != null,
    );
  }

  void toggleAddOn(AddOnType addOn, bool enabled) {
    switch (addOn) {
      case .relax_sounds:
        _preferences = _preferences.copyWith(enableRelaxSounds: enabled);
        break;
      case .period_calendar:
        _preferences = _preferences.copyWith(enablePeriodCalendar: enabled);
        break;
    }

    storage.writeObject(_preferences);
    AnalyticsUserProperyService.instance.logToggleAddOn(addOn: addOn, enabled: enabled);
    _listeners['add_on']?.forEach((listener) => listener());
  }

  void addListenerForAddOnChanges(void Function() listener) {
    _listeners['add_on'] ??= [];
    _listeners['add_on']!.add(listener);
  }

  void removeListenerForAddOnChanges(void Function() listener) {
    _listeners['add_on']?.remove(listener);
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
