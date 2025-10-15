import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/calendar_segment_id.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'calendar_view.dart';

class CalendarViewModel extends ChangeNotifier with DisposeAwareMixin {
  final CalendarRoute params;

  CalendarViewModel({
    required this.params,
    required BuildContext context,
  }) {
    monthYearNotifier = ValueNotifier((
      year: params.initialYear ?? DateTime.now().year,
      month: params.initialMonth ?? DateTime.now().month,
    ));

    provider = context.read<InAppPurchaseProvider>()..addListener(_listener);
    _setSegments();

    selectedSegment = params.initialSegment != null && _segments.contains(params.initialSegment)
        ? params.initialSegment!
        : _segments.first;
  }

  late final InAppPurchaseProvider provider;
  late final ValueNotifier<({int year, int month})> monthYearNotifier;

  late CalendarSegmentId selectedSegment;
  late List<CalendarSegmentId> _segments;

  List<CalendarSegmentId> get segments => _segments;

  void _listener() {
    _setSegments();

    if (!_segments.contains(selectedSegment)) {
      selectedSegment = _segments.first;
    }

    notifyListeners();
  }

  void _setSegments() {
    _segments = [
      CalendarSegmentId.mood,
      if (provider.periodCalendar) CalendarSegmentId.period,
    ];
  }

  @override
  void dispose() {
    provider.removeListener(_listener);
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
