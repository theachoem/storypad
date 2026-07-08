import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/font_weight_extension.dart';
import 'package:storypad/core/objects/app_quick_action_object.dart';
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/core/services/notifications/local_notification_service.dart';
import 'package:storypad/core/types/reminder_type.dart';
import 'package:storypad/core/services/app_quick_actions_service.dart';
import 'package:storypad/core/types/asset_compression_option.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/core/services/analytics/analytics_user_propery_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/core/types/add_on_type.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/maps/map_types.dart';

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
    unawaited(AppQuickActionsService.instance.clearActions());

    // Reset clears reminders; cancel their OS-scheduled notifications too so the
    // native side doesn't keep firing orphaned reminders until the next launch.
    unawaited(LocalNotificationService.instance.rescheduleAll(_preferences.reminders));

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

  void setColorForDay(int weekday, String colorName) {
    final updated = Map<int, String>.from(_preferences.colorByDay ?? {});
    updated[weekday] = colorName;

    _preferences = _preferences.copyWith(colorByDay: updated);
    storage.writeObject(_preferences);
    notifyListeners();
  }

  void resetColorForDay(int weekday) {
    final updated = Map<int, String>.from(_preferences.colorByDay ?? {});
    updated.remove(weekday);

    // Reset to null once there are no customizations left, so stored preferences stay clean.
    _preferences = _preferences.copyWith(colorByDay: updated.isEmpty ? null : updated);
    storage.writeObject(_preferences);
    notifyListeners();
  }

  void resetAllDayColors() {
    _preferences = _preferences.copyWith(colorByDay: null);
    storage.writeObject(_preferences);
    notifyListeners();
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

  void setAssetCompression(AssetCompressionOption value) {
    _preferences = _preferences.copyWith(assetCompression: value);
    storage.writeObject(_preferences);
    notifyListeners();
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

  // No need to notify listeners as it only do sync with system.
  void setHomeQuickActions(List<AppQuickActionObject>? actions) {
    _preferences = _preferences.copyWith(homeQuickActions: actions);
    storage.writeObject(_preferences);
    AppQuickActionsService.instance.setActions(actions);
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

  List<String>? get hiddenStatsSections => preferences.hiddenStatsSections;

  // No need to notifyListeners: the stats view owns this state and only reads it
  // once when opened, so persisting is enough — nothing else in the app reacts.
  void setHiddenStatsSections(List<String> sectionNames) {
    _preferences = _preferences.copyWith(hiddenStatsSections: sectionNames);
    storage.writeObject(_preferences);
  }

  // No need notifyListeners or custom listeners as map is open via navigator and will read latest map style when open.
  // It also manage its own state internally, so no need to notify it of changes.
  void updateMapStyle(SpMapStyle mapStyle) {
    _preferences = _preferences.copyWith(mapStyle: mapStyle);
    storage.writeObject(_preferences);
  }

  List<ReminderObject> get reminders => preferences.reminders ?? const [];
  ReminderObject? reminderOfType(ReminderType type) => reminders.where((r) => r.type == type).firstOrNull;

  ReminderObject? get dailyReminder => reminderOfType(ReminderType.daily);
  ReminderObject? get onThisDayReminder => reminderOfType(ReminderType.onThisDay);
  ReminderObject? get periodReminder => reminderOfType(ReminderType.period);

  List<ReminderObject> get customReminders => reminders.where((r) => r.type == ReminderType.custom).toList();

  /// Small, monotonically increasing id for a new custom reminder. Ids are kept
  /// small because Android notification ids are 32-bit and we derive them as
  /// `reminder.id * 10 + weekday`. Starts at 10 to stay clear of built-in ids.
  int get nextCustomReminderId {
    return reminders.map((r) => r.id).fold<int>(9, (a, b) => a > b ? a : b) + 1;
  }

  // No need for notifyListeners: DevicePreferencesProvider is watched broadly
  // across the app, so it would rebuild far more than the Reminders screen for
  // every reminder edit. Only the Reminders screen cares about this, so it
  // subscribes via addListenerForReminderChanges instead (same pattern as
  // addListenerForAddOnChanges).
  Future<void> _writeReminders(List<ReminderObject> updated) async {
    _preferences = _preferences.copyWith(reminders: updated);
    _listeners['reminders']?.forEach((listener) => listener());
    storage.writeObject(_preferences);

    // Don't block the caller (e.g. a Save button about to pop its sheet/page)
    // on OS notification rescheduling — it cancels and reschedules *every*
    // reminder, including on-this-day's date scan, so it can take a moment.
    // Let it finish in the background instead of stalling the UI dismissal.
    unawaited(LocalNotificationService.instance.rescheduleAll(updated));
  }

  void addListenerForReminderChanges(void Function() listener) {
    _listeners['reminders'] ??= [];
    _listeners['reminders']!.add(listener);
  }

  void removeListenerForReminderChanges(void Function() listener) {
    _listeners['reminders']?.remove(listener);
  }

  /// Inserts or replaces a reminder (matched by id).
  Future<void> upsertReminder(ReminderObject reminder) async {
    final updated = List<ReminderObject>.from(reminders);
    final index = updated.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      updated[index] = reminder;
    } else {
      updated.add(reminder);
    }
    await _writeReminders(updated);
  }

  Future<void> deleteReminder(int id) async {
    final updated = reminders.where((r) => r.id != id).toList();
    await _writeReminders(updated);
  }

  Future<void> toggleReminder(int id, bool enabled) async {
    final updated = reminders.map((r) => r.id == id ? r.copyWith(enabled: enabled) : r).toList();
    await _writeReminders(updated);
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
