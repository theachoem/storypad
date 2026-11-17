/// One logged period: a run of consecutive period days, plus the cycle it opens
/// (start → the next period's start).
class PeriodCycleObject {
  const PeriodCycleObject({
    required this.start,
    required this.end,
    required this.cycleLength,
  });

  /// First logged day of the period (date only).
  final DateTime start;

  /// Last consecutive logged day of the period (date only).
  final DateTime end;

  /// Days from [start] to the next period's start. Null for the latest cycle,
  /// which hasn't ended yet.
  final int? cycleLength;

  /// Number of period days, inclusive of [start] and [end].
  int get periodLength => daysBetween(start, end) + 1;

  /// Whole calendar days from [from] to [to], immune to DST shifts.
  static int daysBetween(DateTime from, DateTime to) {
    return DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }
}
