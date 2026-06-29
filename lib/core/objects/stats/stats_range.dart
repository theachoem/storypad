import 'dart:ui';

import 'package:storypad/core/helpers/date_format_helper.dart';

/// Granularity of a stats range. Prefill-only: month or year.
enum StatsRangeType { month, year }

/// A prefilled, immutable date window the stats screen is computed against.
///
/// Pick a granularity ([StatsRangeType]) and an [anchor] date, and the window
/// snaps to the containing month or year. [previous]/[next] step the anchor by
/// one unit so the UI can page through time.
///
/// [start] is inclusive at 00:00; [end] is inclusive at 23:59:59.999 of the last
/// day, so a simple `>= start && <= end` covers the whole window.
class StatsRange {
  final StatsRangeType type;

  /// Any date inside the window. The window is derived from this, not stored, so
  /// the two can never drift apart.
  final DateTime anchor;

  const StatsRange._(this.type, this.anchor);

  factory StatsRange.month(DateTime anchor) => StatsRange._(StatsRangeType.month, _dateOnly(anchor));
  factory StatsRange.year(DateTime anchor) => StatsRange._(StatsRangeType.year, _dateOnly(anchor));

  factory StatsRange.of(StatsRangeType type, DateTime anchor) {
    switch (type) {
      case StatsRangeType.month:
        return StatsRange.month(anchor);
      case StatsRangeType.year:
        return StatsRange.year(anchor);
    }
  }

  /// First day of the window (00:00).
  DateTime get start {
    switch (type) {
      case StatsRangeType.month:
        return DateTime(anchor.year, anchor.month, 1);
      case StatsRangeType.year:
        return DateTime(anchor.year, 1, 1);
    }
  }

  /// Last day of the window (23:59:59.999).
  DateTime get end {
    final lastDay = switch (type) {
      // Day 0 of next month == last day of this month.
      StatsRangeType.month => DateTime(anchor.year, anchor.month + 1, 0),
      StatsRangeType.year => DateTime(anchor.year, 12, 31),
    };
    return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59, 999);
  }

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

  /// Total whole days in the window (28–31 or 365/366).
  int get totalDays => end.difference(start).inDays + 1;

  /// Month number for a month range, null for a year range — convenient when
  /// building a story query filter.
  int? get month => type == StatsRangeType.month ? anchor.month : null;

  StatsRange get previous {
    switch (type) {
      case StatsRangeType.month:
        return StatsRange.month(DateTime(anchor.year, anchor.month - 1, 1));
      case StatsRangeType.year:
        return StatsRange.year(DateTime(anchor.year - 1, 1, 1));
    }
  }

  StatsRange get next {
    switch (type) {
      case StatsRangeType.month:
        return StatsRange.month(DateTime(anchor.year, anchor.month + 1, 1));
      case StatsRangeType.year:
        return StatsRange.year(DateTime(anchor.year + 1, 1, 1));
    }
  }

  /// The calendar years the window touches (always one).
  Set<int> get years => {start.year};

  /// True when the window includes [now] (i.e. it is the current, in-progress
  /// month/year). Used to cap "days elapsed".
  bool isCurrent([DateTime? now]) => contains(now ?? DateTime.now());

  /// Human label for the selected window, e.g. "June 2026", "2026".
  String label(Locale locale) {
    switch (type) {
      case StatsRangeType.month:
        return DateFormatHelper.yMMMM(start, locale);
      case StatsRangeType.year:
        return DateFormatHelper.y(start, locale);
    }
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}
