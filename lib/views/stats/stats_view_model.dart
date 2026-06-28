import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/objects/stats/stats_range.dart';
import 'package:storypad/core/objects/stats/story_stats_object.dart' show LabelStatItem, StoryStatsObject;
import 'package:storypad/core/services/stories/story_stats_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/stats/stats_section.dart';
import 'package:storypad/widgets/bottom_sheets/sp_picker_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_stories_bottom_sheet.dart';

class StatsViewModel extends ChangeNotifier with DisposeAwareMixin {
  StatsViewModel({
    required StatsRange initialRange,
    required TabController tabController,
  }) : _selectedYear = initialRange.anchor.year,
       _tabController = tabController {
    _tabController.addListener(_onTabChanged);
    loadAvailableYears();
    _loadTabThenPrefetch(_tabController.index);
  }

  int _selectedYear;
  int get selectedYear => _selectedYear;

  final TabController _tabController;

  List<int> _availableYears = [DateTime.now().year];

  // Resolved stats for the *currently selected year only*, keyed '$year-$tabIndex'.
  // Cleared on year change so at most one year is held in memory.
  final Map<String, StoryStatsObject> _statsCache = {};

  // In-flight loads keyed identically to [_statsCache], so each tab is fetched
  // at most once even when the initial load and the prefetch race.
  final Map<String, Future<void>> _loadingByKey = {};

  String _key(int year, int tabIndex) => '$year-$tabIndex';

  /// Returns cached stats for [tabIndex] in the current year, or null while it is
  /// still loading (or not yet requested).
  StoryStatsObject? statsFor(int tabIndex) => _statsCache[_key(_selectedYear, tabIndex)];

  /// Derives the date range for a tab: 0 = full year, 1–12 = that month.
  StatsRange rangeForTab(int tabIndex) =>
      tabIndex == 0 ? StatsRange.year(DateTime(_selectedYear)) : StatsRange.month(DateTime(_selectedYear, tabIndex));

  // Sections the user has hidden (e.g. to declutter a screenshot). Global across
  // tabs/years and in-memory only — resets when the screen is closed. Countries
  // is hidden by default since most users only ever have one.
  static const Set<StatsSection> _defaultHiddenSections = {
    StatsSection.countries,
  };
  final Set<StatsSection> _hiddenSections = {..._defaultHiddenSections};

  bool isSectionVisible(StatsSection section) => !_hiddenSections.contains(section);

  void toggleSection(StatsSection section) {
    if (!_hiddenSections.remove(section)) _hiddenSections.add(section);
    notifyListeners();
  }

  void resetSections() {
    _hiddenSections
      ..clear()
      ..addAll(_defaultHiddenSections);
    notifyListeners();
  }

  /// Sections of the visible tab, listed in the section filter sheet.
  List<StatsSection> sectionsForCurrentTab() => sectionsForTab(_tabController.index);

  /// Whether the visible tab has loaded stats with stories (gates the filter button).
  bool get currentTabHasData {
    final stats = statsFor(_tabController.index);
    return stats != null && !stats.isEmpty;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return; // wait until the tab settles
    notifyListeners(); // keep the AppBar filter menu in sync with the visible tab
    _loadTab(_tabController.index);
  }

  /// Loads [priorityTabIndex] first (the visible tab), then its next and previous
  /// neighbours so an immediate swipe either way is ready, then warms the rest in
  /// order. All loads are deduped via [_loadingByKey], so no tab is fetched twice.
  Future<void> _loadTabThenPrefetch(int priorityTabIndex) async {
    await _loadTab(priorityTabIndex);
    if (priorityTabIndex + 1 <= 12) await _loadTab(priorityTabIndex + 1);
    if (priorityTabIndex - 1 >= 0) await _loadTab(priorityTabIndex - 1);
    for (int tabIndex = 0; tabIndex <= 12; tabIndex++) {
      if (disposed) return;
      await _loadTab(tabIndex);
    }
  }

  /// Returns the cached/in-flight future for [tabIndex], or starts a new fetch.
  Future<void> _loadTab(int tabIndex) {
    final key = _key(_selectedYear, tabIndex);
    if (_statsCache.containsKey(key)) return Future.value();
    return _loadingByKey[key] ??= _fetchTab(
      key: key,
      year: _selectedYear,
      range: rangeForTab(tabIndex),
    );
  }

  Future<void> _fetchTab({
    required String key,
    required int year,
    required StatsRange range,
  }) async {
    try {
      final stories = await StoryDbModel.db.where(
        filters: SearchFilterObject(
          years: range.years,
          types: {PathType.docs},
          assetId: null,
        ).toDatabaseFilter(),
      );

      final tags = await TagDbModel.db.where();

      // Discard if disposed or the year changed mid-flight (stale result).
      if (disposed || year != _selectedYear) return;
      _statsCache[key] = StoryStatsService.compute(
        stories: stories?.items ?? [],
        allTags: tags?.items ?? [],
        range: range,
      );
    } catch (error, stackTrace) {
      debugPrint('StatsViewModel._fetchTab($key) failed: $error\n$stackTrace');
    } finally {
      _loadingByKey.remove(key); // dropping the entry lets a failed tab retry
      if (!disposed) notifyListeners();
    }
  }

  Future<void> pickYear(BuildContext context) {
    return SpPickerSheet(
      selectedValue: _selectedYear,
      options: [for (final y in _availableYears) (value: y, label: '$y')],
      onChanged: (year) {
        if (year == _selectedYear) return; // same year → keep cache, no reload
        _selectedYear = year;
        _statsCache.clear(); // cache holds one year at a time
        _loadingByKey.clear();
        _tabController.animateTo(0); // visual reset to "All"
        _loadTabThenPrefetch(0);
        notifyListeners();
      },
    ).show(context: context);
  }

  void openStoriesForPlace(
    BuildContext context,
    LabelStatItem place,
    int tabIndex,
  ) {
    if (place.storyIds == null) return;
    final range = rangeForTab(tabIndex);
    SpStoriesBottomSheet(
      storyLocation: null,
      filter: SearchFilterObject(
        years: range.years,
        month: range.month,
        types: {PathType.docs},
        storyIds: place.storyIds,
        assetId: null,
      ),
    ).show(context: context);
  }

  void openStoriesForTag(BuildContext context, int tagId, int tabIndex) {
    final range = rangeForTab(tabIndex);
    SpStoriesBottomSheet(
      storyLocation: null,
      filter: SearchFilterObject(
        years: range.years,
        month: range.month,
        types: {PathType.docs},
        tagIds: {tagId},
        assetId: null,
      ),
    ).show(context: context);
  }

  Future<void> loadAvailableYears() async {
    final counts = await StoryDbModel.db.getStoryCountsByYear(
      filters: SearchFilterObject(
        years: {},
        types: {PathType.docs},
        assetId: null,
      ).toDatabaseFilter(),
    );
    if (disposed) return;
    _availableYears = counts.keys.toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    super.dispose();
  }
}
