import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/adaptors/firebase_analytics_user_property_adaptor.dart';
import 'package:storypad/core/services/analytics/adaptors/none_analytics_user_property_adaptor.dart';
import 'package:storypad/core/types/add_on_type.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';

abstract class BaseAnalyticsUserPropertyAdaptor {
  static BaseAnalyticsUserPropertyAdaptor create() {
    return (!kIsWeb && Platform.isLinux) ? NoneAnalyticsUserPropertyAdaptor() : FirebaseAnalyticsUserPropertyAdaptor();
  }

  // ---------------------------------------------------------------------------
  // Primitive method — implement only this in subclasses
  // ---------------------------------------------------------------------------

  Future<void> setUserProperty(String name, String? value);

  // ---------------------------------------------------------------------------
  // High-level methods — implemented once here, shared by all adaptors
  // ---------------------------------------------------------------------------

  Future<void> logSetLocale({required Locale newLocale}) {
    return setUserProperty('locale', newLocale.toLanguageTag());
  }

  Future<void> logSetColorSeedTheme({Color? newColor}) {
    return setUserProperty('color_seed', newColor?.toARGB32().toString() ?? 'default');
  }

  Future<void> logSetThemeMode({required ThemeMode newThemeMode}) {
    return setUserProperty('theme_mode', newThemeMode.name);
  }

  Future<void> logSetFontWeight({required FontWeight newFontWeight}) {
    return setUserProperty('font_weight', newFontWeight.value.toString());
  }

  Future<void> logSetFontFamily({required String newFontFamily}) {
    return setUserProperty('font_family', newFontFamily);
  }

  Future<void> logSetFontSize({required FontSizeOption? newFontSize}) {
    return setUserProperty('font_size', newFontSize?.name ?? 'system');
  }

  Future<void> logSetTimeFormat({required TimeFormatOption timeFormat}) {
    return setUserProperty('time_format', timeFormat.label);
  }

  Future<void> logSetFirstDayOfWeek({required FirstDayOfWeekOption firstDayOfWeek}) {
    return setUserProperty('first_day_of_week', firstDayOfWeek.name);
  }

  Future<void> logToggleAddOn({required AddOnType addOn, required bool enabled}) {
    return setUserProperty('add_on_${addOn.name}', enabled.toString());
  }

  Future<void> logSetStoryTilePreferences({
    required bool showTime,
    required bool showPageCount,
    required bool showTagLabels,
    required bool showVoiceCount,
    required int displayCharacterCount,
  }) async {
    await setUserProperty('list_show_time', showTime.toString());
    await setUserProperty('list_show_page_count', showPageCount.toString());
    await setUserProperty('list_show_tag_labels', showTagLabels.toString());
    await setUserProperty('list_show_voice_count', showVoiceCount.toString());
    await setUserProperty('list_char_count', displayCharacterCount.toString());
  }

  Future<void> logSetDefaultStoryPreferences({
    required String defaultLayoutType,
    required bool hasColorSeed,
    required bool hasBackground,
  }) async {
    await setUserProperty('default_default_layout', defaultLayoutType);
    await setUserProperty('default_has_color_seed', hasColorSeed.toString());
    await setUserProperty('default_has_background', hasBackground.toString());
  }

  Future<void> logSetAppLogo({required AppLogo? newAppLogo}) {
    return setUserProperty('app_logo', newAppLogo?.name ?? 'default');
  }
}
