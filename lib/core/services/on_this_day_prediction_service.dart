import 'package:storypad/core/databases/models/story_db_model.dart';

/// Finds upcoming calendar dates that have past journal entries ("on this day"
/// memories), so we can schedule a notification only on days that actually
/// have something to show — instead of firing every single day.
///
/// Local notifications can't run Dart code at delivery time to decide whether
/// to show up, so this precomputes matching dates within a bounded horizon and
/// schedules one-shot notifications only for those.
class OnThisDayPredictionService {
  /// Pure: given a callback reporting whether a given (month, day) has past
  /// memories, returns up to [maxResults] dates (starting from [from],
  /// inclusive) within [horizonDays] that have memories. Kept side-effect free
  /// so it's unit-testable without a database.
  static List<DateTime> findUpcomingMemoryDates({
    required DateTime from,
    required bool Function(int month, int day) hasMemoriesOn,
    int horizonDays = 30,
    int maxResults = 20,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final matches = <DateTime>[];

    for (int offset = 0; offset <= horizonDays && matches.length < maxResults; offset++) {
      final date = start.add(Duration(days: offset));
      if (hasMemoriesOn(date.month, date.day)) matches.add(date);
    }

    return matches;
  }

  /// Loads matching dates from the database using indexed month/day `count()`
  /// queries only (no row hydration, no events join), so this stays cheap even
  /// across a 30-day horizon — safe to run on every app launch / reschedule.
  static Future<List<DateTime>> loadUpcomingMemoryDates({
    DateTime? now,
    int horizonDays = 30,
    int maxResults = 20,
  }) async {
    return findUpcomingMemoryDates(
      from: now ?? DateTime.now(),
      horizonDays: horizonDays,
      maxResults: maxResults,
      hasMemoriesOn: (month, day) {
        return StoryDbModel.db
                .buildQuery(
                  filters: {
                    'month': month,
                    'day': day,
                    'types': ['docs', 'archives'],
                  },
                )
                .build()
                .count() >
            0;
      },
    );
  }
}
