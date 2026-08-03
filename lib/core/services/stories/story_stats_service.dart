import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/stats/stats_range.dart';
import 'package:storypad/core/objects/stats/story_stats_object.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';

/// Aggregates a list of stories into a [StoryStatsObject] for one [StatsRange].
///
/// Pure and side-effect free so it can be unit-tested in isolation: pass the
/// stories, the tag dictionary (to resolve ids → emoji/category/title), the
/// range, and optionally a fixed [now] for deterministic "days elapsed" math.
/// Stories outside the range are filtered out here, so callers can pass a whole
/// year and let the service narrow it.
///
/// Tag-backed buckets (feelings, activities, tags, people) are keyed by tag id
/// rather than by display string, so each ranked item carries the id needed to
/// open the filtered stories sheet on tap.
class StoryStatsService {
  static StoryStatsObject compute({
    required List<StoryDbModel> stories,
    required List<TagDbModel> allTags,
    required StatsRange range,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();
    final Map<int, TagDbModel> tagById = {for (final tag in allTags) tag.id: tag};

    final int feelingCategoryId = TagCategoryDbModel.feeling().id;
    final int activityCategoryId = TagCategoryDbModel.activity().id;

    int entryCount = 0;
    int wordCount = 0;
    int photoCount = 0;
    int videoCount = 0;
    int voiceCount = 0;
    int locatedCount = 0;

    final Set<int> photoStoryIds = {};
    final Set<int> videoStoryIds = {};
    final Set<int> voiceStoryIds = {};
    final Set<int> locatedStoryIds = {};

    final Set<DateTime> activeDaySet = {};
    final Map<DateTime, int> dailyCounts = {};

    final Map<int, int> feelingCounts = {};
    final Map<int, int> activityCounts = {};
    final Map<int, int> tagCounts = {};
    final Map<int, int> peopleCounts = {};
    final Map<String, Set<int>> placeStoryIds = {};
    final Map<String, int> countryCounts = {};

    for (final StoryDbModel story in stories) {
      final DateTime date = story.displayPathDate;
      if (!range.contains(date)) continue;

      entryCount++;

      final DateTime day = DateTime(date.year, date.month, date.day);
      activeDaySet.add(day);
      dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;

      final content = story.latestContent ?? story.draftContent;
      wordCount += content?.wordCount ?? 0;

      final int storyPhotoCount = StoryContentEmbedExtractor.photos(content).length;
      final int storyVideoCount = StoryContentEmbedExtractor.videos(content).length;
      final int storyVoiceCount = StoryContentEmbedExtractor.audio(content).length;
      photoCount += storyPhotoCount;
      videoCount += storyVideoCount;
      voiceCount += storyVoiceCount;
      if (storyPhotoCount > 0) photoStoryIds.add(story.id);
      if (storyVideoCount > 0) videoStoryIds.add(story.id);
      if (storyVoiceCount > 0) voiceStoryIds.add(story.id);

      if (story.hasLocation) {
        locatedCount++;
        locatedStoryIds.add(story.id);
        final place = story.place!;
        (placeStoryIds[place.displayLabel] ??= {}).add(story.id);
        final country = place.country;
        if (country != null && country.isNotEmpty) {
          countryCounts[country] = (countryCounts[country] ?? 0) + 1;
        }
      }

      for (final int tagId in story.validTags ?? const <int>[]) {
        final TagDbModel? tag = tagById[tagId];
        if (tag == null) continue;

        if (tag.emoji != null) {
          if (tag.categoryId == feelingCategoryId) {
            feelingCounts[tagId] = (feelingCounts[tagId] ?? 0) + 1;
          } else if (tag.categoryId == activityCategoryId) {
            activityCounts[tagId] = (activityCounts[tagId] ?? 0) + 1;
          }
        } else if (tag.isPerson) {
          peopleCounts[tagId] = (peopleCounts[tagId] ?? 0) + 1;
        } else if (tag.categoryId == null) {
          tagCounts[tagId] = (tagCounts[tagId] ?? 0) + 1;
        }
      }
    }

    return StoryStatsObject(
      entryCount: entryCount,
      activeDays: activeDaySet.length,
      totalDays: _elapsedDays(range, today),
      wordCount: wordCount,
      photoCount: photoCount,
      videoCount: videoCount,
      voiceCount: voiceCount,
      locatedCount: locatedCount,
      photoStoryIds: photoStoryIds,
      videoStoryIds: videoStoryIds,
      voiceStoryIds: voiceStoryIds,
      locatedStoryIds: locatedStoryIds,
      topFeelings: _topEmojis(feelingCounts, tagById),
      topActivities: _topEmojis(activityCounts, tagById),
      topTags: _topTagLabels(tagCounts, tagById),
      topPeople: _topTagLabels(peopleCounts, tagById),
      topPlaces: _topPlaceLabels(placeStoryIds),
      topCountries: _topCountryLabels(countryCounts),
      dailyCounts: dailyCounts,
    );
  }

  /// Days the range is scored against: full length for a finished window, days
  /// elapsed so far for the current one.
  static int _elapsedDays(StatsRange range, DateTime now) {
    if (!range.isCurrent(now)) return range.totalDays;
    final DateTime today = DateTime(now.year, now.month, now.day);
    return today.difference(range.start).inDays + 1;
  }

  static List<EmojiStatItem> _topEmojis(Map<int, int> counts, Map<int, TagDbModel> tagById) {
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => EmojiStatItem(tagId: e.key, emoji: tagById[e.key]?.emoji ?? '', count: e.value))
        .where((item) => item.emoji.isNotEmpty)
        .toList();
  }

  static List<LabelStatItem> _topTagLabels(Map<int, int> counts, Map<int, TagDbModel> tagById) {
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => LabelStatItem(label: tagById[e.key]?.title ?? '', count: e.value, tagId: e.key))
        .where((item) => item.label.isNotEmpty)
        .toList();
  }

  static List<LabelStatItem> _topPlaceLabels(Map<String, Set<int>> placeStoryIds) {
    final entries = placeStoryIds.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    return entries.map((e) => LabelStatItem(label: e.key, count: e.value.length, storyIds: e.value)).toList();
  }

  static List<LabelStatItem> _topCountryLabels(Map<String, int> counts) {
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => LabelStatItem(label: e.key, count: e.value)).toList();
  }
}
