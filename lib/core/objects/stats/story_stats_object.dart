import 'package:easy_localization/easy_localization.dart';

/// A single emoji tag (feeling / activity) and how many stories used it in the
/// range. [tagId] lets the UI open the filtered stories sheet on tap.
class EmojiStatItem {
  final int tagId;
  final String emoji;
  final int count;
  const EmojiStatItem({required this.tagId, required this.emoji, required this.count});
}

/// A named bucket (tag, person, place, country) and its story count. [tagId] is
/// the backing tag id for tag/person rows (so they can open the filtered stories
/// sheet); null for places/countries. [storyIds] is populated for place rows so
/// the UI can open a filtered stories sheet without a second DB query.
class LabelStatItem {
  final String label;
  final int count;
  final int? tagId;
  final Set<int>? storyIds;
  const LabelStatItem({required this.label, required this.count, this.tagId, this.storyIds});
}

/// Fully-aggregated stats for one [StatsRange]. Pure data: holds raw counts and
/// pre-ranked top-N lists produced by [StoryStatsService]; presentation getters
/// only pluralize/format. The screen renders sections straight off this object.
class StoryStatsObject {
  /// Stories written in the range.
  final int entryCount;

  /// Distinct days with at least one story.
  final int activeDays;

  /// Days the activity is scored against: full range length for a finished
  /// window, or days elapsed so far for the in-progress one.
  final int totalDays;

  /// Words written across all stories' latest content.
  final int wordCount;

  /// Photos embedded across the range (video excluded).
  final int photoCount;

  /// Videos embedded across the range.
  final int videoCount;

  /// Voice notes embedded across the range.
  final int voiceCount;

  /// Stories that carry a location.
  final int locatedCount;

  /// Ids of stories that embed at least one photo, used to open the filtered
  /// stories sheet when the overview "photos" chip is tapped.
  final Set<int> photoStoryIds;

  /// Ids of stories that embed at least one video (overview "videos" chip).
  final Set<int> videoStoryIds;

  /// Ids of stories that embed at least one voice note (overview "voices" chip).
  final Set<int> voiceStoryIds;

  /// Ids of stories that carry a location (overview "places" chip).
  final Set<int> locatedStoryIds;

  final List<EmojiStatItem> topFeelings;
  final List<EmojiStatItem> topActivities;
  final List<LabelStatItem> topTags;
  final List<LabelStatItem> topPeople;
  final List<LabelStatItem> topPlaces;
  final List<LabelStatItem> topCountries;

  /// Story count per day, keyed by a date-only [DateTime] (00:00). Drives the
  /// entries-over-time trend.
  final Map<DateTime, int> dailyCounts;

  const StoryStatsObject({
    required this.entryCount,
    required this.activeDays,
    required this.totalDays,
    required this.wordCount,
    required this.photoCount,
    required this.videoCount,
    required this.voiceCount,
    required this.locatedCount,
    required this.photoStoryIds,
    required this.videoStoryIds,
    required this.voiceStoryIds,
    required this.locatedStoryIds,
    required this.topFeelings,
    required this.topActivities,
    required this.topTags,
    required this.topPeople,
    required this.topPlaces,
    required this.topCountries,
    required this.dailyCounts,
  });

  /// No stories at all in the range — the screen shows an empty state instead of
  /// a grid of zeros.
  bool get isEmpty => entryCount == 0;

  /// "12 of 30 days" coverage headline, reusing the recap key.
  String get activeDaysLabel => tr(
    'page.home.story_recap.active_days',
    namedArgs: {'SP_ACTIVE': '$activeDays', 'SP_TOTAL': '$totalDays'},
  );
}
