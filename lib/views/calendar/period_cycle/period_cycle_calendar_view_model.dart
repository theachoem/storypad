import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'period_cycle_calendar_view.dart';

class PeriodCycleCalendarViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PeriodCycleCalendarView params;

  PeriodCycleCalendarViewModel({
    required this.params,
  });
}
