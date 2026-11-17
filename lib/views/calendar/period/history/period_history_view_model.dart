import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/period_cycle_object.dart';
import 'package:storypad/core/services/period_prediction_service.dart';
import 'period_history_view.dart';

class PeriodHistoryViewModel extends ChangeNotifier with DisposeAwareMixin {
  final PeriodHistoryRoute params;

  PeriodHistoryViewModel({required this.params}) {
    load();
  }

  /// Newest first; null while loading. Sample cycles while [isDemo].
  List<PeriodCycleObject>? cycles;

  /// Nothing logged yet: the page previews itself with sample data instead of
  /// an empty message, so users see what logging gets them.
  bool isDemo = false;

  double? averageCycleLength;
  double? averagePeriodLength;
  DateTime? predictedNextStart;

  /// Fallback "usual" cycle before there are two logged starts to average.
  static const int _defaultCycleLength = 28;

  /// Bounds on the usual cycle used for display. Sparse logging can push the
  /// raw average way out (two starts a year apart average 365 days), which
  /// would disable the gap guard below; clamping to a realistic range keeps
  /// it working. Display-only — the prediction keeps the raw average.
  static const int _minUsualCycleLength = 21;
  static const int _maxUsualCycleLength = 45;

  int get _usualCycleLength =>
      (averageCycleLength?.round() ?? _defaultCycleLength).clamp(_minUsualCycleLength, _maxUsualCycleLength);

  /// Anything longer than twice the usual cycle is a logging gap (or tracking
  /// stopped), not a real cycle, so the latest cycle stops counting days.
  int get _longCycleDays => 2 * _usualCycleLength;

  Future<void> load() async {
    final loggedDates = await PeriodPredictionService.loadPeriodDates();
    isDemo = loggedDates.isEmpty;

    final dates = isDemo ? _demoPeriodDates(DateTime.now()) : loggedDates;
    final all = PeriodPredictionService.groupCycles(dates);
    final recent = PeriodPredictionService.recentCycles(all);

    averageCycleLength = PeriodPredictionService.averageCycleLength(recent);
    averagePeriodLength = PeriodPredictionService.averagePeriodLength(recent);
    predictedNextStart = PeriodPredictionService.predictNextPeriodStart(dates);
    cycles = all.reversed.toList();

    notifyListeners();
  }

  /// Day of the ongoing cycle (1 = its start day), or null when [cycle] has
  /// already ended, starts in the future, or started so long ago (beyond
  /// [_longCycleDays]) that it's no longer being tracked.
  int? currentCycleDay(PeriodCycleObject cycle) {
    if (cycle.cycleLength != null) return null;
    final day = PeriodCycleObject.daysBetween(cycle.start, DateTime.now()) + 1;
    return day >= 1 && day <= _longCycleDays ? day : null;
  }

  void openCycle(BuildContext context, PeriodCycleObject cycle) {
    Navigator.of(context).pop(cycle.start);
  }

  /// Back to the calendar, on the current month, to log a first period.
  void openCalendar(BuildContext context) {
    Navigator.of(context).pop(DateTime.now());
  }

  /// A plausible recent history relative to [now]: three ended 28-30 day
  /// cycles and an ongoing one, 5-6 period days each. Run through the same
  /// grouping/averaging/prediction as real data, so the preview is honest.
  static List<DateTime> _demoPeriodDates(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    const periods = [
      (daysAgo: 96, length: 5),
      (daysAgo: 66, length: 6),
      (daysAgo: 38, length: 5),
      (daysAgo: 9, length: 5),
    ];
    return [
      for (final period in periods)
        for (int i = 0; i < period.length; i++) DateTime(today.year, today.month, today.day - period.daysAgo + i),
    ];
  }
}
