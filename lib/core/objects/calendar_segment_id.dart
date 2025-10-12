import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum CalendarSegmentId {
  stories,
  periodCycle;

  String translatedName(BuildContext context) {
    switch (this) {
      case CalendarSegmentId.stories:
        return tr('general.stories');
      case CalendarSegmentId.periodCycle:
        return 'Period Cycle';
    }
  }
}
