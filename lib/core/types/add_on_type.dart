// ignore_for_file: constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:storypad/widgets/sp_icons.dart';

enum AddOnType {
  relax_sounds(icon: SpIcons.musicNote, weekdayColor: 4),
  period_calendar(icon: SpIcons.waterDrop, designForFemale: true, weekdayColor: 7)
  ;

  final IconData icon;
  final bool designForFemale;
  final int weekdayColor;

  const AddOnType({
    required this.icon,
    required this.weekdayColor,
    this.designForFemale = false,
  });

  String get displayName {
    switch (this) {
      case AddOnType.relax_sounds:
        return tr("paywall_features.relax_sounds.title");
      case AddOnType.period_calendar:
        return tr("list_tile.period_calendar.title");
    }
  }

  String get description {
    switch (this) {
      case AddOnType.relax_sounds:
        return tr('paywall_features.relax_sounds.subtitle');
      case AddOnType.period_calendar:
        return tr('list_tile.period_calendar.subtitle');
    }
  }
}
