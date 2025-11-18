import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

enum TimeFormatOption {
  h12,
  h24
  ;

  String get label {
    switch (this) {
      case TimeFormatOption.h12:
        return '12-Hour';
      case TimeFormatOption.h24:
        return '24-Hour';
    }
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
