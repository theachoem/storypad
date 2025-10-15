import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum CalendarSegmentId {
  mood,
  period;

  String translatedName(BuildContext context) {
    switch (this) {
      case CalendarSegmentId.mood:
        return tr('general.mood');
      case CalendarSegmentId.period:
        return tr('add_ons.period_calendar.title');
    }
  }
}
