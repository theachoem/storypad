import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

/// Aggregated stats for a single month, rendered by the timeline recap tile.
///
/// Holds raw counts only; presentation getters turn them into localized,
/// pluralized strings so the UI just renders and joins them. Add a new stat by
/// adding a count field here and one line to [labels] — the tile needs no change.
class MonthRecapStatsObject {
  /// Month of the year, 1 (January) – 12 (December).
  final int month;

  /// Number of stories written this month.
  final int storyCount;

  /// Total photos embedded across this month's stories.
  final int photoCount;

  /// Total voice notes embedded across this month's stories.
  final int voiceCount;

  /// Distinct days that have at least one story.
  final int activeDays;

  /// Days the month is scored against: the full calendar length for a past
  /// month, or the days elapsed so far for the in-progress month (so the
  /// current month isn't penalized for not having happened yet).
  final int totalDays;

  const MonthRecapStatsObject({
    required this.month,
    required this.storyCount,
    required this.photoCount,
    required this.voiceCount,
    required this.activeDays,
    required this.totalDays,
  });

  bool get shouldShowRecap => storyCount >= 5;

  /// Headline coverage label, e.g. "12 of 31 days".
  String get activeDaysLabel => tr(
    'page.home.story_recap.active_days',
    namedArgs: {'SP_ACTIVE': '$activeDays', 'SP_TOTAL': '$totalDays'},
  );

  String titleLabel(Locale locale) => tr(
    'page.home.story_recap.title',
    namedArgs: {'SP_MONTH': DateFormatHelper.MMMM(DateTime(2000, month), locale)},
  );

  /// Localized, pluralized stat strings to be joined by the UI (e.g. with " · ").
  /// Zero-valued media stats are skipped so the tile never shows "0 photos".
  List<String> get labels => [
    plural('plural.entry', storyCount),
    if (photoCount > 0) plural('plural.photo', photoCount),
    if (voiceCount > 0) plural('plural.voice', voiceCount),
  ];
}
