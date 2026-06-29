import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/month_recap_stats_object.dart';
import 'package:storypad/core/services/days_count_in_month_service.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';

/// Aggregates a single year's stories into per-month recap stats.
///
/// Pure and side-effect free so it can be unit-tested in isolation: pass in the
/// stories (and optionally a fixed [now] for deterministic "days elapsed"
/// math) and get back a `month -> stats` map. The view model just calls this
/// and holds the result.
class MonthlyStoryStatsService {
  /// Returns recap stats keyed by month of the year (1–12). Months without any
  /// stories are absent from the map.
  static Map<int, MonthRecapStatsObject> getByMonth({
    required List<StoryDbModel> stories,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();

    final Map<int, List<StoryDbModel>> storiesByMonth = {};
    for (final StoryDbModel story in stories) {
      storiesByMonth.putIfAbsent(story.month, () => []).add(story);
    }

    final Map<int, MonthRecapStatsObject> result = {};
    storiesByMonth.forEach((int month, List<StoryDbModel> monthStories) {
      final int year = monthStories.first.year;

      int photoCount = 0;
      int voiceCount = 0;
      final Set<int> activeDays = {};

      for (final StoryDbModel story in monthStories) {
        final content = story.latestContent ?? story.draftContent;
        photoCount += StoryContentEmbedExtractor.images(content).length;
        voiceCount += StoryContentEmbedExtractor.audio(content).length;
        activeDays.add(story.displayPathDate.day);
      }

      final bool isCurrentMonth = year == today.year && month == today.month;
      final int totalDays = isCurrentMonth ? today.day : DaysCountInMonthService.get(year: year, month: month);

      result[month] = MonthRecapStatsObject(
        month: month,
        storyCount: monthStories.length,
        photoCount: photoCount,
        voiceCount: voiceCount,
        activeDays: activeDays.length,
        totalDays: totalDays,
      );
    });

    return result;
  }
}
