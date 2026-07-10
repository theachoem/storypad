import 'package:storypad/core/databases/models/event_db_model.dart';

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
    final days = periodDates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();

    // A day is a cycle start when the previous calendar day isn't also a
    // period day — this groups consecutive logged days (a single period,
    // possibly spanning a month boundary) into one cycle start.
    final daySet = days.toSet();
    final allStarts = <DateTime>[
      for (final day in days)
        if (!daySet.contains(day.subtract(const Duration(days: 1)))) day,
    ];

    if (allStarts.length < minCycleStarts) return null;

    final today = now ?? DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    // If even the most recent logged start predates our recency window
    // (relative to today, not to that start itself), the history is too
    // stale to extrapolate from — bail rather than roll a long-dead cycle
    // forward into a misleadingly confident future date.
    final staleCutoff = DateTime(todayDay.year, todayDay.month - maxHistoryMonths, todayDay.day);
    if (allStarts.last.isBefore(staleCutoff)) return null;

    final cutoff = DateTime(allStarts.last.year, allStarts.last.month - maxHistoryMonths, allStarts.last.day);
    var starts = allStarts.where((d) => !d.isBefore(cutoff)).toList();
    // The 6-month window can leave too few points (e.g. sparse logging) —
    // fall back to the most recent [minCycleStarts] starts so we still predict.
    if (starts.length < minCycleStarts) {
      starts = allStarts.sublist(allStarts.length - minCycleStarts);
    }

    int totalGap = 0;
    for (int i = 1; i < starts.length; i++) {
      totalGap += starts[i].difference(starts[i - 1]).inDays;
    }
    final avgCycle = (totalGap / (starts.length - 1)).round();
    if (avgCycle <= 0) return null;

    var next = starts.last.add(Duration(days: avgCycle));
    // Roll forward whole cycles if the naive prediction is already in the past.
    while (next.isBefore(todayDay)) {
      next = next.add(Duration(days: avgCycle));
    }
    return next;
  }

  /// Loads period history from the database and predicts the next start date.
  static Future<DateTime?> loadPredictedNextPeriodStart({DateTime? now}) async {
    final collection = await EventDbModel.db.where(filters: {"event_type": "period"});
    final dates = collection?.items.map((e) => e.date).whereType<DateTime>().toList() ?? [];
    return predictNextPeriodStart(dates, now: now);
  }
}
