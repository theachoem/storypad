import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
import 'calendar_view.dart';

class CalendarViewModel extends ChangeNotifier with DisposeAwareMixin {
  final CalendarRoute params;

  CalendarViewModel({
    required this.params,
  }) {
    monthNotifier = ValueNotifier<int>(params.initialMonth ?? DateTime.now().month);
    yearNotifier = ValueNotifier<int>(params.initialYear ?? DateTime.now().year);
  }

  @override
  void dispose() {
    monthNotifier.dispose();
    yearNotifier.dispose();
    super.dispose();
  }

  CalendarSegmentId selectedSegment = CalendarSegmentId.stories;

  late final ValueNotifier<int> monthNotifier;
  late final ValueNotifier<int> yearNotifier;

  void onSegmentChanged(CalendarSegmentId segment) {
    selectedSegment = segment;
    notifyListeners();
  }

  void onMonthYearChanged(int newYear, int newMonth) {
    yearNotifier.value = newYear;
    monthNotifier.value = newMonth;
  }
}
