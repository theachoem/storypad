import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

enum TimeFormatOption {
  h12,
  h24;

  String get label {
    switch (this) {
      case TimeFormatOption.h12:
        return '12-Hour';
      case TimeFormatOption.h24:
        return '24-Hour';
    }
  }

  /// Resolves the effective time format, falling back to the device's
  /// 24-hour setting ([MediaQuery.alwaysUse24HourFormatOf]) when the user
  /// hasn't customized it.
  static TimeFormatOption resolve(BuildContext context, TimeFormatOption? preference) {
    if (preference != null) return preference;
    return MediaQuery.alwaysUse24HourFormatOf(context) ? TimeFormatOption.h24 : TimeFormatOption.h12;
  }

  String formatTime(DateTime date, Locale locale) {
    if (this == h12) {
      return DateFormatHelper.jm(date, locale);
    } else {
      return DateFormatHelper.Hm(date, locale);
    }
  }

  String formatDateTime(DateTime date, Locale locale) {
    if (this == h12) {
      return DateFormatHelper.yMEd_jm(date, locale);
    } else {
      return DateFormatHelper.yMEd_Hm(date, locale);
    }
  }
}
