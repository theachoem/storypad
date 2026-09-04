part of '../home_view_model.dart';

/// A [GlobalKey] whose identity is [value] equality (`==`), unlike
/// [GlobalObjectKey] which compares by reference (`identical`). Needed here
/// because [HomeViewModel._buildItems] reconstructs the whole [HomeItem]
/// array — and therefore a brand new key value (e.g. a `(year, month)`
/// record) — on every call, including once per background-prefetched page;
/// a fresh anonymous `GlobalKey()` per rebuild would make Flutter treat
/// every already-mounted tile as a new widget and remount it (dropping
/// `SpStoryListenerBuilder`'s DB listener, causing visible flicker). Keying
/// by stable content instead lets Flutter recognize "this is still the same
/// story/header" and preserve its element across rebuilds.
class _HomeValueKey extends GlobalKey {
  const _HomeValueKey(this.value) : super.constructor();

  final Object value;

  @override
  bool operator ==(Object other) => other is _HomeValueKey && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

sealed class HomeItem {
  GlobalKey get key;

  /// Non-null only for story-backed items; used for scroll-to-story lookups
  /// (`items.indexWhere((item) => item.storyId == id)`).
  int? get storyId;
}

/// Shared fields for the two "renders as a story tile" cases. Kept as a
/// mixin (not a shared non-leaf class) so [HomeStoryItem]/[HomePinnedStoryItem]
/// stay direct, distinct subtypes of the sealed [HomeItem] for exhaustive
/// switching.
mixin HomeStoryFields {
  StoryDbModel get story;

  /// previousStory == null || !previousStory.sameDayAs(story)
  bool get showMonogram;

  /// true when there's a later story in this run, so the timeline's
  /// VerticalDivider should run the full tile height instead of a short stub.
  bool get showFullTimelineDivider;
}

final class HomeThrowbackItem extends HomeItem {
  HomeThrowbackItem({required this.throwbackDates, required this.listHasStories});

  // Only ever one throwback tile in the list at a time.
  @override
  final GlobalKey key = const _HomeValueKey('throwback');

  @override
  int? get storyId => null;

  final List<DateTime> throwbackDates;
  final bool listHasStories;
}

final class HomeMonthHeaderItem extends HomeItem {
  HomeMonthHeaderItem({required this.story, required this.isFirstOfRun, required this.pinned});

  @override
  GlobalKey get key => _HomeValueKey(('header', pinned, story.year, story.month));

  @override
  int? get storyId => null;

  final StoryDbModel story;

  /// True when this header is at local index 0 of its run (the pinned run or
  /// the unpinned run) — drives the header's extra top spacing when there's
  /// no throwback tile, and whether a connector divider to the previous
  /// section is drawn.
  final bool isFirstOfRun;

  /// Which run this header belongs to — pinned and unpinned runs each have
  /// their own headers, so (year, month) alone isn't a unique key.
  final bool pinned;
}

final class HomeMonthRecapItem extends HomeItem {
  HomeMonthRecapItem({required this.story, required this.stats, required this.showFullTimelineDivider});

  // Recap tiles only ever appear in the unpinned run.
  @override
  GlobalKey get key => _HomeValueKey(('recap', story.year, story.month));

  @override
  int? get storyId => null;

  final StoryDbModel story;
  final MonthRecapStatsObject stats;
  final bool showFullTimelineDivider;
}

final class HomeStoryItem extends HomeItem with HomeStoryFields {
  HomeStoryItem({required this.story, required this.showMonogram, required this.showFullTimelineDivider});

  // A story id only ever appears in one of the pinned/unpinned runs at a
  // time, so no "pinned" tag is needed to keep this unique.
  @override
  GlobalKey get key => _HomeValueKey(('story', story.id));

  @override
  int? get storyId => story.id;

  @override
  final StoryDbModel story;

  @override
  final bool showMonogram;

  @override
  final bool showFullTimelineDivider;
}

/// Trailing sentinel appended when [HomeViewModel.hasMoreStories] is true.
/// `SliverList.builder` only builds items near the viewport, so this item's
/// widget being built is itself the "user scrolled near the loaded edge"
/// signal — its build calls [HomeViewModel.loadNextPage], which is cheap to
/// call redundantly (joins an already in-flight fetch instead of double
/// fetching) since the background pager (see [HomeViewModel.reload]) is
/// already eagerly working through remaining pages regardless of scroll.
final class HomeLoadMoreItem extends HomeItem {
  // Only ever one load-more tile in the list at a time.
  @override
  final GlobalKey key = const _HomeValueKey('load-more');

  @override
  int? get storyId => null;
}

final class HomePinnedStoryItem extends HomeItem with HomeStoryFields {
  HomePinnedStoryItem({required this.story, required this.showMonogram, required this.showFullTimelineDivider});

  @override
  GlobalKey get key => _HomeValueKey(('story', story.id));

  @override
  int? get storyId => story.id;

  @override
  final StoryDbModel story;

  @override
  final bool showMonogram;

  @override
  final bool showFullTimelineDivider;
}
