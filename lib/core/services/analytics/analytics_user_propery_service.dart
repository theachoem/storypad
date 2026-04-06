import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/base_analytics_service.dart';
import 'package:storypad/core/types/add_on_type.dart';
import 'package:storypad/core/types/app_logo.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';

// Logging analytics events without user-identifiable information.
class AnalyticsUserProperyService extends BaseAnalyticsService {
  AnalyticsUserProperyService._();
  static AnalyticsUserProperyService get instance => AnalyticsUserProperyService._();

  Future<void> logSetLocale({
    required Locale newLocale,
  }) {
    debug('logSetLocale', {'value': newLocale.toLanguageTag()});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'locale',
      value: newLocale.toLanguageTag(),
    );
  }

  Future<void> logSetColorSeedTheme({
    Color? newColor,
  }) {
    debug('logSetColorSeedTheme', {'value': newColor.toString()});

    return FirebaseAnalytics.instance.setUserProperty(
      value: newColor?.toARGB32().toString() ?? 'default',
      name: 'color_seed',
    );
  }

  Future<void> logSetThemeMode({
    required ThemeMode newThemeMode,
  }) {
    debug('logSetThemeMode', {'value': newThemeMode.name});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'theme_mode',
      value: newThemeMode.name,
    );
  }

  Future<void> logSetFontWeight({
    required FontWeight newFontWeight,
  }) {
    debug('logSetFontWeight', {'value': newFontWeight.value.toString()});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'font_weight',
      value: newFontWeight.value.toString(),
    );
  }

  Future<void> logSetFontFamily({
    required String newFontFamily,
  }) {
    debug('logSetFontFamily', {'value': newFontFamily});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'font_family',
      value: newFontFamily,
    );
  }

  Future<void> logSetFontSize({
    required FontSizeOption? newFontSize,
  }) {
    debug('logSetFontSize', {'value': newFontSize?.name ?? 'system'});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'font_size',
      value: newFontSize?.name ?? 'system',
    );
  }

  Future<void> logSetTimeFormat({
    required TimeFormatOption timeFormat,
  }) {
    debug('logSetTimeFormat', {'value': timeFormat.name});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'time_format',
      value: timeFormat.label,
    );
  }

  Future<void> logToggleAddOn({
    required AddOnType addOn,
    required bool enabled,
  }) {
    debug('logToggleAddOn', {'add_on': addOn.name, 'enabled': enabled.toString()});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'add_on_${addOn.name}',
      value: enabled.toString(),
    );
  }

  Future<void> logSetStoryTilePreferences({
    required bool showTime,
    required bool showPageCount,
    required bool showTagLabels,
    required bool showVoiceCount,
    required int displayCharacterCount,
  }) async {
    debug('logSetStoryTilePreferences', {
      'show_time': showTime.toString(),
      'show_page_count': showPageCount.toString(),
      'show_tag_labels': showTagLabels.toString(),
      'show_voice_count': showVoiceCount.toString(),
      'display_character_count': displayCharacterCount.toString(),
    });

    await FirebaseAnalytics.instance.setUserProperty(name: 'list_show_time', value: showTime.toString());
    await FirebaseAnalytics.instance.setUserProperty(name: 'list_show_page_count', value: showPageCount.toString());
    await FirebaseAnalytics.instance.setUserProperty(name: 'list_show_tag_labels', value: showTagLabels.toString());
    await FirebaseAnalytics.instance.setUserProperty(name: 'list_show_voice_count', value: showVoiceCount.toString());
    await FirebaseAnalytics.instance.setUserProperty(name: 'list_char_count', value: displayCharacterCount.toString());
  }

  Future<void> logSetDefaultStoryPreferences({
    required String defaultLayoutType,
    required bool hasColorSeed,
    required bool hasBackground,
  }) async {
    debug('logSetDefaultStoryPreferences', {
      'default_layout_type': defaultLayoutType,
      'has_color_seed': hasColorSeed.toString(),
      'has_background': hasBackground.toString(),
    });

    await FirebaseAnalytics.instance.setUserProperty(name: 'default_default_layout', value: defaultLayoutType);
    await FirebaseAnalytics.instance.setUserProperty(name: 'default_has_color_seed', value: hasColorSeed.toString());
    await FirebaseAnalytics.instance.setUserProperty(name: 'default_has_background', value: hasBackground.toString());
  }

  Future<void> logSetAppLogo({
    required AppLogo? newAppLogo,
  }) {
    debug('logSetAppLogo', {'value': newAppLogo?.name ?? 'default'});

    return FirebaseAnalytics.instance.setUserProperty(
      name: 'app_logo',
      value: newAppLogo?.name ?? 'default',
    );
  }
}
