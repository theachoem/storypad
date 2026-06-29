import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/objects/stats/story_stats_object.dart';

/// A toggleable block on the stats screen. Identifies the section in the filter
/// sheet and the body.
enum StatsSection {
  overview,
  feelings,
  activities,
  tags,
  people,
  places,
  countries,
  trend;

  /// Localized section title. Keys are passed to `tr` as literals (not via a
  /// variable) so the unused-translations scanner can see they are used.
  String get label => switch (this) {
    StatsSection.overview => tr('page.stats.section.overview'),
    StatsSection.feelings => tr('page.stats.section.feelings'),
    StatsSection.activities => tr('page.stats.section.activities'),
    StatsSection.tags => tr('page.stats.section.tags'),
    StatsSection.people => tr('page.stats.section.people'),
    StatsSection.places => tr('page.stats.section.places'),
    StatsSection.countries => tr('page.stats.section.countries'),
    StatsSection.trend => tr('page.stats.section.trend'),
  };

  /// Whether the section has enough data to render its content (otherwise the
  /// body shows a "not enough data" placeholder). Countries needs more than one
  /// distinct country to be meaningful.
  bool hasEnoughData(StoryStatsObject stats) => switch (this) {
    StatsSection.overview => true,
    StatsSection.feelings => stats.topFeelings.isNotEmpty,
    StatsSection.activities => stats.topActivities.isNotEmpty,
    StatsSection.tags => stats.topTags.isNotEmpty,
    StatsSection.people => stats.topPeople.isNotEmpty,
    StatsSection.places => stats.topPlaces.isNotEmpty,
    StatsSection.countries => stats.topCountries.length > 1,
    StatsSection.trend => true,
  };
}

/// Ordered sections shown on [tabIndex] (0 = year). Trend is year-only.
List<StatsSection> sectionsForTab(int tabIndex) => [
  StatsSection.overview,
  StatsSection.feelings,
  StatsSection.activities,
  StatsSection.tags,
  StatsSection.people,
  StatsSection.places,
  StatsSection.countries,
  if (tabIndex == 0) StatsSection.trend,
];
