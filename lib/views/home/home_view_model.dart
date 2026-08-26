import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/month_recap_stats_object.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/stories/monthly_story_stats_service.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/assets/app_file_picker_service.dart';
import 'package:storypad/core/services/assets/insert_file_to_db_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/in_app_review_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/voice_recorder_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer_state.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_recording_sheet.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';

part 'local_widgets/home_scroll_info.dart';
part 'local_widgets/home_scroll_app_bar_info.dart';
part 'local_widgets/home_item.dart';

class HomeViewModel extends ChangeNotifier with DisposeAwareMixin {
  late final scrollInfo = _HomeScrollInfo(viewModel: () => this);

  HomeViewModel() {
    AnalyticsService.instance.logViewHome(year: year);
    reload(debugSource: 'HomeViewModel#_constructor');

    BackupProvider.repoInstance.restoreService.addListener(_restoreServiceListener);
  }

  int year = DateTime.now().year;

  List<DateTime>? _throwbackDates;
  List<DateTime>? get throwbackDates => _throwbackDates;

  bool get hasThrowback => _throwbackDates?.isNotEmpty == true;
  bool get hasPinned => _pinnedStories?.items.isNotEmpty == true;

  CollectionDbModel<StoryDbModel>? _stories;
  CollectionDbModel<StoryDbModel>? get stories => _stories;

  CollectionDbModel<StoryDbModel>? _pinnedStories;
  CollectionDbModel<StoryDbModel>? get pinnedStories => _pinnedStories;

  /// Unpinned stories load a page at a time (see [loadNextPage]) so initial
  /// paint stays fast regardless of how many stories the year has. Pinned
  /// stories are always loaded in full — typically a small set.
  static const int _pageSize = 60;

  /// Non-null while a page fetch is in flight. A second caller (the eager
  /// background pager and, redundantly, [HomeLoadMoreItem] scrolling into
  /// view) awaits this same [Completer] instead of racing a duplicate fetch.
  Completer<void>? _pageFetchCompleter;

  bool _hasMoreStories = true;
  bool get hasMoreStories => _hasMoreStories;

  /// Distinct months (1-12) with at least one story in [year], from a cheap
  /// DB-side query — independent of how many pages of [stories] have loaded,
  /// so the month tab bar is correct from the first frame.
  List<int> _monthsForYear = [];

  /// Per-month recap stats for the current year, keyed by month (1–12).
  /// Recomputed synchronously in [setStories] from the *confirmed-complete*
  /// prefix of [stories] (see [_confirmedCompleteUnpinnedStories]) — the
  /// same data already fetched for the story list, no separate DB fetch. A
  /// month's recap tile and its own story tiles are therefore always built
  /// together in the same [_buildItems] pass — never a retroactive pop-in
  /// once a month "catches up".
  Map<int, MonthRecapStatsObject> _monthlyStats = {};
  Map<int, MonthRecapStatsObject> get monthlyStats => _monthlyStats;

  List<HomeItem> _items = [];

  /// Flattened, single-source-of-truth render list for the home `SliverList`:
  /// throwback tile, then pinned run, then unpinned run — each run interleaved
  /// with its own month-header/recap items. Rebuilt in full on every
  /// [setStories] call, mirroring the old behavior of regenerating all
  /// GlobalKeys unconditionally on every data change.
  List<HomeItem> get items => _items;

  void setStories(CollectionDbModel<StoryDbModel>? value, CollectionDbModel<StoryDbModel>? pinnedValue) {
    _stories = value?.deduplicateAndSort(
      comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
    );
    _pinnedStories = pinnedValue?.deduplicateAndSort(
      comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
    );

    StoryContentEmbedExtractor.preloadAssetAspectRatios([...?stories?.items, ...?pinnedStories?.items]);

    final renderableStories = _confirmedCompleteUnpinnedStories(stories?.items ?? []);
    _monthlyStats = MonthlyStoryStatsService.getByMonth(stories: renderableStories);
    _items = _buildItems(renderableStories);
  }

  /// Trims the trailing (possibly still-loading) month off [allUnpinnedStories]
  /// so a month never renders — nor gets a recap tile — until every one of
  /// its stories has loaded. Stories load newest-first (see [loadNextPage]),
  /// so only the very last month in the list can be split across a page
  /// boundary; every earlier month is already guaranteed complete, since a
  /// story from a different (older) month couldn't have appeared after it
  /// otherwise. Once [_hasMoreStories] is false there's no next page left to
  /// split anything, so nothing needs trimming.
  List<StoryDbModel> _confirmedCompleteUnpinnedStories(List<StoryDbModel> allUnpinnedStories) {
    if (allUnpinnedStories.isEmpty || !_hasMoreStories) return allUnpinnedStories;

    final last = allUnpinnedStories.last;
    int cut = allUnpinnedStories.length;
    while (cut > 0 &&
        allUnpinnedStories[cut - 1].year == last.year &&
        allUnpinnedStories[cut - 1].month == last.month) {
      cut--;
    }
    return allUnpinnedStories.sublist(0, cut);
  }

  List<HomeItem> _buildItems(List<StoryDbModel> renderableStories) {
    final items = <HomeItem>[];

    if (hasThrowback) {
      items.add(
        HomeThrowbackItem(
          throwbackDates: throwbackDates ?? [],
          listHasStories: stories?.items.isNotEmpty == true,
        ),
      );
    }

    // Pinned run: headers yes, recap tiles never (matches the previous
    // `eligibleToShowRecap: false` behavior for pinned stories). Pinned
    // stories aren't paginated, so no completeness trimming needed here.
    items.addAll(_buildRunItems(pinnedStories?.items ?? [], pinned: true, monthlyStats: null));
    items.addAll(_buildRunItems(renderableStories, pinned: false, monthlyStats: _monthlyStats));

    if (_hasMoreStories) items.add(HomeLoadMoreItem());

    return items;
  }

  List<HomeItem> _buildRunItems(
    List<StoryDbModel> run, {
    required bool pinned,
    required Map<int, MonthRecapStatsObject>? monthlyStats,
  }) {
    final result = <HomeItem>[];

    for (int i = 0; i < run.length; i++) {
      final story = run[i];
      final previous = i > 0 ? run[i - 1] : null;
      final next = i + 1 < run.length ? run[i + 1] : null;
      final showFullTimelineDivider = next != null;
      final showMonogram = previous == null || !previous.sameDayAs(story);

      if (previous?.month != story.month || previous?.year != story.year) {
        result.add(HomeMonthHeaderItem(story: story, isFirstOfRun: i == 0, pinned: pinned));

        final monthStats = monthlyStats?[story.month];
        if (monthStats != null && monthStats.shouldShowRecap) {
          result.add(
            HomeMonthRecapItem(
              story: story,
              stats: monthStats,
              showFullTimelineDivider: showFullTimelineDivider,
            ),
          );
        }
      }

      result.add(
        pinned
            ? HomePinnedStoryItem(
                story: story,
                showMonogram: showMonogram,
                showFullTimelineDivider: showFullTimelineDivider,
              )
            : HomeStoryItem(
                story: story,
                showMonogram: showMonogram,
                showFullTimelineDivider: showFullTimelineDivider,
              ),
      );
    }

    return result;
  }

  List<int> get months => _monthsForYear.isNotEmpty ? _monthsForYear : [DateTime.now().month];

  Future<void> reload({
    required String debugSource,
  }) async {
    AppLogger.d('🚧 Reload home from $debugSource 🏠');

    _pageFetchCompleter = null;
    _hasMoreStories = true;

    final pinnedStories = await StoryDbModel.db.where(
      filters: SearchFilterObject(
        years: {year},
        types: {PathType.docs},
        pinned: true,
        assetId: null,
      ).toDatabaseFilter(),
    );

    _pinnedStories = pinnedStories?.deduplicateAndSort(
      comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
    );

    _throwbackDates = DateTime.now().year == year
        ? await StoryDbModel.db
              .where(
                filters: SearchFilterObject(
                  years: {},
                  excludeYears: {DateTime.now().year},
                  month: DateTime.now().month,
                  day: DateTime.now().day,
                  types: {PathType.docs, PathType.archives},
                  assetId: null,
                ).toDatabaseFilter(),
              )
              .then((e) => e?.items.map((e) => e.displayPathDate).toSet().toList())
        : null;

    _monthsForYear = StoryDbModel.db.getMonthsForYear(
      year: year,
      filters: {'types': PathType.values.map((e) => e.name).toList()},
    );

    // reset: true so this fetches offset 0 regardless of whatever [_stories]
    // still holds from before this reload (the old year/search-refresh data,
    // kept visible on screen until this swaps it in — not cleared upfront,
    // to avoid flashing the loading spinner on every year switch / pull to
    // refresh). setStories()/notifyListeners() happen inside.
    await loadNextPage(reset: true);

    unawaited(_prefetchRemainingPages());
  }

  /// Eagerly works through every remaining page in the background right
  /// after page 1, rather than waiting for the user to scroll near the
  /// loaded edge — [loadNextPage] is cheap to also call from scroll/jump
  /// paths since it just joins this same in-flight fetch instead of racing
  /// a duplicate one.
  Future<void> _prefetchRemainingPages() async {
    final requestedYear = year;
    while (_hasMoreStories && year == requestedYear) {
      await loadNextPage();
    }
  }

  /// Loads the next page of unpinned stories (see [_pageSize]), appending
  /// into [stories]. Uses `stories.items.length` as the offset rather than a
  /// separately tracked cursor, so a concurrent delete/pin-toggle that
  /// shrinks the in-memory list can't desync the cursor — worst case is one
  /// re-fetched row, which [setStories]'s dedupe already discards.
  ///
  /// [reset] is for [reload] only: fetches offset 0 and *replaces* [stories]
  /// instead of appending, regardless of whatever's currently loaded (the
  /// old year/search's data — deliberately left in place until this swaps
  /// it, so switching years doesn't flash the loading spinner). This gives
  /// page 1 and every later page the same fetch path instead of a
  /// near-duplicate inline fetch for "just the first one".
  ///
  /// If a fetch is already in flight (typically [_prefetchRemainingPages]),
  /// this joins that same fetch via [_pageFetchCompleter] instead of racing
  /// a duplicate query.
  Future<void> loadNextPage({bool reset = false}) {
    if (_pageFetchCompleter != null) return _pageFetchCompleter!.future;
    if (!reset && !_hasMoreStories) return Future.value();

    final completer = Completer<void>();
    _pageFetchCompleter = completer;

    _fetchNextPage(reset: reset).then(completer.complete, onError: completer.completeError).whenComplete(() {
      _pageFetchCompleter = null;
    });

    return completer.future;
  }

  Future<void> _fetchNextPage({required bool reset}) async {
    final requestedYear = year;
    final offset = reset ? 0 : (stories?.items.length ?? 0);
    AppLogger.d('🚧 $runtimeType#loadNextPage fetching offset: $offset, limit: $_pageSize, year: $requestedYear');

    final nextPage = await StoryDbModel.db.where(
      filters: SearchFilterObject(
        years: {year},
        types: {PathType.docs},
        pinned: false,
        assetId: null,
        limit: _pageSize,
        offset: offset,
      ).toDatabaseFilter(),
    );

    if (requestedYear != year) {
      // Year changed while this page was in flight — reload() already
      // started a fresh fetch for the new year, discard this one.
      AppLogger.d('🚧 $runtimeType#loadNextPage discarded: year changed $requestedYear -> $year mid-flight');
      return;
    }

    _hasMoreStories = (nextPage?.items.length ?? 0) == _pageSize;
    AppLogger.d(
      '🚧 $runtimeType#loadNextPage loaded ${nextPage?.items.length ?? 0} more stories '
      '(total: ${offset + (nextPage?.items.length ?? 0)}), hasMore: $_hasMoreStories',
    );

    setStories(
      CollectionDbModel<StoryDbModel>(items: [if (!reset) ...?stories?.items, ...?nextPage?.items]),
      pinnedStories,
    );
    notifyListeners();
  }

  Future<void> refresh(BuildContext context) async {
    await reload(debugSource: '$runtimeType#refresh');
  }

  Future<void> changeYear(int newYear) async {
    if (year == newYear) return;

    year = newYear;
    await reload(debugSource: '$runtimeType#changeYear $newYear');

    AnalyticsService.instance.logViewHome(
      year: year,
    );
  }

  Future<void> goToViewPage(BuildContext context, StoryDbModel story) async {
    final editedStory = await ShowStoryRoute(id: story.id, story: story).push(context);

    if (editedStory is StoryDbModel && editedStory.updatedAt != story.updatedAt) {
      year = editedStory.year;
      await reload(debugSource: '$runtimeType#goToNewPage');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollInfo.moveToStory(targetStoryId: editedStory.id);
      });
    }
  }

  Future<void> goToNewPage(BuildContext context) async {
    final addedStory = await EditStoryRoute(
      id: null,
      initialYear: year,
    ).push(context);
    await _checkNewStoryResult(addedStory);
  }

  Future<void> goToNewPageWithVoice(BuildContext context) async {
    return SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final result = await const SpVoiceRecordingSheet().show(context: context);
        if (result is! VoiceRecordingResult) return;
        if (HomeView.homeContext?.mounted != true) return;

        final asset = await InsertFileToDbService.insertAudio(
          result.filePath,
          durationInMs: result.durationInMs,
        );

        if (asset == null) return;

        final addedStory = await EditStoryRoute(
          id: null,
          initialYear: year,
          initialAsset: asset,
        ).push(HomeView.homeContext!);

        await _checkNewStoryResult(addedStory);
      },
    );
  }

  void takePhoto(BuildContext context) async {
    return SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final compression = context.read<DevicePreferencesProvider>().preferences.assetCompression;
        final photo = await AppFilePickerService.pickImage(
          source: ImageSource.camera,
          compression: compression,
        );
        if (photo == null) return;

        AssetDbModel? asset = await InsertFileToDbService.insertImage(photo.file, size: photo.size);
        if (asset == null) return;

        AnalyticsService.instance.logTakePhoto();

        final addedStory = await EditStoryRoute(
          id: null,
          initialYear: year,
          initialAsset: asset,
        ).push(HomeView.homeContext!);

        await _checkNewStoryResult(addedStory);
      },
    );
  }

  void recordVideo(BuildContext context) async {
    return SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final compression = context.read<DevicePreferencesProvider>().preferences.assetCompression;
        final video = await AppFilePickerService.pickVideo(
          context: context,
          source: ImageSource.camera,
          compression: compression,
        );
        if (video == null) return;

        AssetDbModel? asset = await InsertFileToDbService.insertVideo(video.file, size: video.size);
        if (asset == null) return;

        AnalyticsService.instance.logRecordVideo();

        final addedStory = await EditStoryRoute(
          id: null,
          initialYear: year,
          initialAsset: asset,
        ).push(HomeView.homeContext!);

        await _checkNewStoryResult(addedStory);
      },
    );
  }

  Future<void> goToTemplatePage(BuildContext context) async {
    final addedStory = await TemplatesRoute(
      initialYear: year,
    ).push(context);
    await _checkNewStoryResult(addedStory);
  }

  bool showFadeInYearEndDrawer = false;
  HomeEndDrawerState endDrawerState = HomeEndDrawerState.showSettings;
  Future<void> openSettings(BuildContext context) async {
    showFadeInYearEndDrawer = true;
    endDrawerState = HomeEndDrawerState.showSettings;
    AnalyticsService.instance.logOpenHomeEndDrawer(year: year);
    Scaffold.of(context).openEndDrawer();
  }

  Future<void> openYearsView(BuildContext context) async {
    showFadeInYearEndDrawer = false;
    endDrawerState = HomeEndDrawerState.showYearsView;
    AnalyticsService.instance.logOpenHomeEndDrawer(year: year);
    Scaffold.of(context).openEndDrawer();
  }

  Future<void> togglePinForStories(SpStoryListMultiEditWrapperState state, BuildContext context) async {
    final allStories = [
      ...stories?.items.where((story) {
            return state.selectedStories.contains(story.id);
          }) ??
          [],
      ...pinnedStories?.items.where((story) {
            return state.selectedStories.contains(story.id);
          }) ??
          [],
    ];

    if (allStories.isEmpty) return;

    final allPinned = allStories.every((story) => story.pinned == true);
    final firstStoryId = allStories.first.id;

    if (allPinned) {
      await state.unpinAll(context);
    } else {
      await state.pinAll(context);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollInfo.moveToStory(targetStoryId: firstStoryId);
    });
  }

  void onAStoryDeleted(StoryDbModel story) {
    AppLogger.d('🚧 Removed ${story.id}:${story.type.name} by $runtimeType#onAStoryDeleted');
    setStories(stories?.removeElement(story), pinnedStories?.removeElement(story));
    notifyListeners();
  }

  void onAStoryReloaded(StoryDbModel updatedStory) {
    if (updatedStory.type != PathType.docs) {
      setStories(stories?.removeElement(updatedStory), pinnedStories?.removeElement(updatedStory));
      AppLogger.d('🚧 Removed ${updatedStory.id}:${updatedStory.type.name} by $runtimeType#onAStoryReloaded');
    } else {
      if (updatedStory.pinned == true) {
        if (pinnedStories == null || pinnedStories?.items.isEmpty == true) {
          setStories(
            stories?.removeElement(updatedStory),
            CollectionDbModel(items: [updatedStory]),
          );
        } else {
          setStories(
            stories?.removeElement(updatedStory),
            pinnedStories?.exists(updatedStory.id) == true
                ? pinnedStories?.replaceElement(updatedStory)
                : pinnedStories?.addElement(updatedStory, 0),
          );
        }
      } else {
        // pinned == false or pinned == null — both treated as unpinned,
        // consistent with the DB query which uses: pinned.equals(false).or(pinned.isNull())
        if (stories == null || stories?.items.isEmpty == true) {
          setStories(
            CollectionDbModel(items: [updatedStory]),
            pinnedStories?.removeElement(updatedStory),
          );
        } else {
          setStories(
            stories?.exists(updatedStory.id) == true
                ? stories?.replaceElement(updatedStory)
                : stories?.addElement(updatedStory, 0),
            pinnedStories?.removeElement(updatedStory),
          );
        }
      }
      AppLogger.d('🚧 Updated ${updatedStory.id}:${updatedStory.type.name} contents by $runtimeType#onAStoryReloaded');
    }
    notifyListeners();
  }

  Future<void> _checkNewStoryResult(Object? addedStory) async {
    if (stories != null && addedStory is StoryDbModel) {
      if (year == addedStory.year) {
        // setStories will automatically sort the stories by displayPathDate
        // Check existence before adding to prevent duplicates
        if (addedStory.pinned == true) {
          final pinnedCollection = pinnedStories ?? CollectionDbModel(items: []);
          final isNew = !pinnedCollection.exists(addedStory.id) && !(stories?.exists(addedStory.id) ?? false);
          setStories(
            stories?.removeElement(addedStory),
            pinnedCollection.exists(addedStory.id)
                ? pinnedCollection.replaceElement(addedStory)
                : pinnedCollection.addElement(addedStory, 0),
          );
          if (isNew) unawaited(InAppReviewService.maybeRequest());
        } else {
          final storiesCollection = stories ?? CollectionDbModel(items: []);
          final isNew = !storiesCollection.exists(addedStory.id) && !(pinnedStories?.exists(addedStory.id) ?? false);
          setStories(
            storiesCollection.exists(addedStory.id)
                ? storiesCollection.replaceElement(addedStory)
                : storiesCollection.addElement(addedStory, 0),
            pinnedStories?.removeElement(addedStory),
          );
          if (isNew) unawaited(InAppReviewService.maybeRequest());
        }
        notifyListeners();
      } else {
        await MessengerService.of(HomeView.homeContext!).showLoading(
          debugSource: '$runtimeType#_checkNewStoryResult',
          future: () async {
            year = addedStory.year;
            await reload(debugSource: '$runtimeType#_checkNewStoryResult');
          },
        );
        unawaited(InAppReviewService.maybeRequest());
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollInfo.moveToStory(targetStoryId: addedStory.id);
      });
    } else {
      // reload all time ensure data consistency.
      // inconsistent data may occur when adding story from different year.
      await reload(debugSource: '$runtimeType#_checkNewStoryResult');
    }
  }

  Future<void> _restoreServiceListener() async {
    reload(debugSource: '$runtimeType#_listenToRestoreService');
  }

  @override
  void dispose() {
    scrollInfo.dispose();
    BackupProvider.repoInstance.restoreService.removeListener(_restoreServiceListener);
    super.dispose();
  }
}
