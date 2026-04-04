import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum CalendarSegmentId {
  mood,
  period
  ;

  String translatedName(BuildContext context) {
    switch (this) {
      case CalendarSegmentId.mood:
        return tr('general.mood');
      case CalendarSegmentId.period:
        return tr('paywall_features.period_calendar.title');
    }
  }
}
