import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/objects/period_cycle_object.dart';

/// Predicts the next period start date from logged period days.
///
/// Period days are stored individually (one [EventDbModel] per day). This service
/// groups consecutive days into cycles, takes each cycle's first day as a start,
/// averages the gap between starts, and projects the next start.
class PeriodPredictionService {
  /// Minimum number of logged cycle starts needed before we'll predict anything.
  static const int minCycleStarts = 2;

  /// Cycle starts older than this many months (relative to the most recent
  /// start) are dropped before averaging — recent cycles predict better than
  /// year-old ones, and capping the window keeps the average cheap and easy
  /// to explain ("based on your last 6 months").
  static const int maxHistoryMonths = 6;

  /// Pure prediction from a list of period day-dates (flat, one entry per
  /// logged day — a single cycle may span a month boundary, e.g. Jan
  /// 27–Feb 2). Returns null when there isn't enough history (fewer than
  /// [minCycleStarts] distinct cycle starts, grouped from consecutive days),
  /// or when the most recent logged start is older than [maxHistoryMonths]
  /// relative to `now` (nothing recent enough to extrapolate from).
  static DateTime? predictNextPeriodStart(List<DateTime> periodDates, {DateTime? now}) {
    final cycles = groupCycles(periodDates);
    if (cycles.length < minCycleStarts) return null;

    final today = now ?? DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    // If even the most recent logged start predates our recency window
    // (relative to today, not to that start itself), the history is too
    // stale to extrapolate from — bail rather than roll a long-dead cycle
    // forward into a misleadingly confident future date.
    final staleCutoff = DateTime(todayDay.year, todayDay.month - maxHistoryMonths, todayDay.day);
    if (cycles.last.start.isBefore(staleCutoff)) return null;

    final avgCycle = averageCycleLength(recentCycles(cycles))?.round();
    if (avgCycle == null || avgCycle <= 0) return null;

    var next = cycles.last.start.add(Duration(days: avgCycle));
    // Roll forward whole cycles if the naive prediction is already in the past.
    while (next.isBefore(todayDay)) {
      next = next.add(Duration(days: avgCycle));
    }
    return next;
  }

  /// Groups flat period day-dates into cycles, oldest first. A day starts a
  /// new cycle when the previous calendar day isn't also a period day, so a
  /// single period spanning a month boundary (e.g. Jan 27–Feb 2) stays one
  /// cycle. Each cycle's length runs to the next cycle's start; the latest
  /// cycle's is null.
  static List<PeriodCycleObject> groupCycles(List<DateTime> periodDates) {
    final days = periodDates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();

    final runs = <({DateTime start, DateTime end})>[];
    for (final day in days) {
      if (runs.isNotEmpty && PeriodCycleObject.daysBetween(runs.last.end, day) == 1) {
        runs.last = (start: runs.last.start, end: day);
      } else {
        runs.add((start: day, end: day));
      }
    }

    return [
      for (int i = 0; i < runs.length; i++)
        PeriodCycleObject(
          start: runs[i].start,
          end: runs[i].end,
          cycleLength: i + 1 < runs.length ? PeriodCycleObject.daysBetween(runs[i].start, runs[i + 1].start) : null,
        ),
    ];
  }

  /// Cycles within [maxHistoryMonths] of the latest start — the same window
  /// [predictNextPeriodStart] averages over, so stats shown next to the
  /// prediction agree with it.
  ///
  /// The window can leave too few points (e.g. sparse logging) — then it falls
  /// back to the most recent [minCycleStarts] cycles so there's still a gap to
  /// average.
  static List<PeriodCycleObject> recentCycles(List<PeriodCycleObject> cycles) {
    if (cycles.isEmpty) return cycles;
    final latest = cycles.last.start;
    final cutoff = DateTime(latest.year, latest.month - maxHistoryMonths, latest.day);
    final recent = cycles.where((c) => !c.start.isBefore(cutoff)).toList();
    if (recent.length >= minCycleStarts || cycles.length < minCycleStarts) return recent;
    return cycles.sublist(cycles.length - minCycleStarts);
  }

  /// Mean start-to-start gap over [cycles] that have ended; null when none has.
  static double? averageCycleLength(List<PeriodCycleObject> cycles) {
    final lengths = cycles.map((c) => c.cycleLength).whereType<int>().toList();
    if (lengths.isEmpty) return null;
    return lengths.reduce((a, b) => a + b) / lengths.length;
  }

  /// Mean number of period days over [cycles]; null when empty.
  static double? averagePeriodLength(List<PeriodCycleObject> cycles) {
    if (cycles.isEmpty) return null;
    return cycles.map((c) => c.periodLength).reduce((a, b) => a + b) / cycles.length;
  }

  /// All logged period day-dates from the database.
  static Future<List<DateTime>> loadPeriodDates() async {
    final collection = await EventDbModel.db.where(filters: {"event_type": "period"});
    return collection?.items.map((e) => e.date).whereType<DateTime>().toList() ?? [];
  }

  /// Loads period history from the database and predicts the next start date.
  static Future<DateTime?> loadPredictedNextPeriodStart({DateTime? now}) async {
    return predictNextPeriodStart(await loadPeriodDates(), now: now);
  }
}
