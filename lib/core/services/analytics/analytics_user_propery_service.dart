import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/base_analytics_service.dart';
import 'package:storypad/core/types/font_size_option.dart';

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
      // TODO: fix deprecated_member_use
      // ignore: deprecated_member_use
      value: newColor?.value.toString() ?? 'default',
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
}
