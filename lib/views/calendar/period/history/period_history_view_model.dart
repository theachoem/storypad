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

  /// Newest first; null while loading.
  List<PeriodCycleObject>? cycles;

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
  /// stopped), not a real cycle: the latest cycle stops counting days, and
  /// long gaps fill the bar instead of shrinking every other bar to a sliver.
  int get _longCycleDays => 2 * _usualCycleLength;

  /// Days a full-width bar stands for, shared by every row.
  int _barScaleDays = 1;

  Future<void> load() async {
    final dates = await PeriodPredictionService.loadPeriodDates();
    final all = PeriodPredictionService.groupCycles(dates);
    final recent = PeriodPredictionService.recentCycles(all);

    averageCycleLength = PeriodPredictionService.averageCycleLength(recent);
    averagePeriodLength = PeriodPredictionService.averagePeriodLength(recent);
    predictedNextStart = PeriodPredictionService.predictNextPeriodStart(dates);
    cycles = all.reversed.toList();
    final longestBar = cycles!.fold(1, (max, c) => _barDays(c) > max ? _barDays(c) : max);
    _barScaleDays = longestBar < _longCycleDays ? longestBar : _longCycleDays;

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

  /// Days the cycle's bar represents: the full cycle once it ended, else the
  /// days elapsed so far (never shorter than the period itself).
  int _barDays(PeriodCycleObject cycle) {
    final days = cycle.cycleLength ?? currentCycleDay(cycle) ?? 0;
    return days > cycle.periodLength ? days : cycle.periodLength;
  }

  /// Bar width as a fraction of the row; gaps past the scale fill it.
  double barFraction(PeriodCycleObject cycle) => (_barDays(cycle) / _barScaleDays).clamp(0.04, 1.0);

  /// Bar days after the period itself (drawn as the rest of the cycle).
  int barRestDays(PeriodCycleObject cycle) => _barDays(cycle) - cycle.periodLength;

  void openCycle(BuildContext context, PeriodCycleObject cycle) {
    Navigator.of(context).pop(cycle.start);
  }
}
