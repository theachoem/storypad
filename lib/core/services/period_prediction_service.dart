import 'package:storypad/core/databases/models/event_db_model.dart';

/// Predicts the next period start date from logged period days.
///
/// Period days are stored individually (one [EventDbModel] per day). This service
/// groups consecutive days into cycles, takes each cycle's first day as a start,
/// averages the gap between starts, and projects the next start.
class PeriodPredictionService {
  /// Pure prediction from a list of period day-dates. Returns null when there
  /// isn't enough history (fewer than 2 distinct cycle starts).
  static DateTime? predictNextPeriodStart(List<DateTime> periodDates, {DateTime? now}) {
    if (periodDates.length < 2) return null;

    final days = periodDates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();

    // A day is a cycle start when the previous calendar day isn't also a period day.
    final daySet = days.toSet();
    final starts = <DateTime>[
      for (final day in days)
        if (!daySet.contains(day.subtract(const Duration(days: 1)))) day,
    ];

    if (starts.length < 2) return null;

    int totalGap = 0;
    for (int i = 1; i < starts.length; i++) {
      totalGap += starts[i].difference(starts[i - 1]).inDays;
    }
    final avgCycle = (totalGap / (starts.length - 1)).round();
    if (avgCycle <= 0) return null;

    final today = now ?? DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

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
