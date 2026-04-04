import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'calendar_view.dart';

class CalendarViewModel extends ChangeNotifier with DisposeAwareMixin {
  final CalendarRoute params;
  final BuildContext viewContext;

  CalendarViewModel({
    required this.params,
    required this.viewContext,
  }) {
    monthYearNotifier = ValueNotifier((
      year: params.initialYear ?? DateTime.now().year,
      month: params.initialMonth ?? DateTime.now().month,
    ));

    _setSegments();
    selectedSegment = params.initialSegment != null && _segments.contains(params.initialSegment)
        ? params.initialSegment!
        : _segments.first;
  }

  late final ValueNotifier<({int year, int month})> monthYearNotifier;

  late CalendarSegmentId selectedSegment;
  late List<CalendarSegmentId> _segments;

  List<CalendarSegmentId> get segments => _segments;

  void _setSegments() {
    _segments = [
      CalendarSegmentId.mood,

      // Use read (no need to listen) as this view is opened as sheet, so the enabled status is ready before this page is being built.
      if (viewContext.read<DevicePreferencesProvider>().enablePeriodCalendar(viewContext)) CalendarSegmentId.period,
    ];
  }

  @override
  void dispose() {
    monthYearNotifier.dispose();
    super.dispose();
  }

  void onSegmentChanged(CalendarSegmentId segment) {
    selectedSegment = segment;
    notifyListeners();
  }

  void onMonthYearChanged(int newYear, int newMonth) {
    monthYearNotifier.value = (year: newYear, month: newMonth);
  }
}
