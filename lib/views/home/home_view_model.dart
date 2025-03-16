import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/storages/search_filter_storage.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'package:storypad/widgets/bottom_sheets/search_filter_bottom_sheet.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/in_app_review_service.dart';
import 'package:storypad/core/services/backups/restore_backup_service.dart';
import 'package:storypad/core/storages/new_stories_count_storage.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/nickname_bottom_sheet.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

part './local_widgets/home_scroll_info.dart';
part 'local_widgets/home_scroll_app_bar_info.dart';

class HomeViewModel extends BaseViewModel {
  late final scrollInfo = _HomeScrollInfo(viewModel: () => this);

  HomeViewModel({
    required BuildContext context,
  }) {
    nickname = PreferenceDbModel.db.nickname.get();

    loadSearchFilter().then((e) {
      AnalyticsService.instance.logViewHome(year: currentSearchFilter.years.first);
      reload(debugSource: 'HomeViewModel#_constructor');

      RestoreBackupService.instance.addListener(() async {
        reload(debugSource: '$runtimeType#_listenToRestoreService');
      });
    });
  }

  String? nickname;

  int get currentYear => DateTime.now().year;
  int get year => currentSearchFilter.years.firstOrNull ?? currentYear;
  int? get filteredTagId => currentSearchFilter.tagId;

  bool get filtered =>
      jsonEncode(currentSearchFilter.toDatabaseFilter()) != jsonEncode(initialSearchFilter.toDatabaseFilter());

  CollectionDbModel<StoryDbModel>? _stories;
  CollectionDbModel<StoryDbModel>? get stories => _stories;
  void setStories(CollectionDbModel<StoryDbModel>? value) {
    _stories = value;
    scrollInfo.setupStoryKeys(stories?.items ?? []);
  }

  List<int> get months {
    List<int> months = stories?.items.map((e) => e.month).toSet().toList() ?? [];
    if (months.isEmpty) months.add(DateTime.now().month);
    return months;
  }

  SearchFilterObject get initialSearchFilter => SearchFilterObject(
        years: {currentYear},
        types: {PathType.docs},
        tagId: null,
        assetId: null,
      );

  SearchFilterObject? _currentSearchFilter;
  SearchFilterObject get currentSearchFilter => _currentSearchFilter ?? initialSearchFilter;

  Future<void> reload({
    required String debugSource,
  }) async {
    debugPrint('🚧 Reload home from $debugSource 🏠');

    nickname = PreferenceDbModel.db.nickname.get();
    final stories = await StoryDbModel.db.where(filters: currentSearchFilter.toDatabaseFilter());

    setStories(stories);
    notifyListeners();
  }

  Future<void> loadSearchFilter() async {
    _currentSearchFilter = await SearchFilterStorage().readObject() ?? initialSearchFilter;
    _currentSearchFilter = _currentSearchFilter!.copyWith(types: {PathType.docs});

    if (_currentSearchFilter?.years.isEmpty == true) {
      _currentSearchFilter = _currentSearchFilter!.copyWith(years: {currentYear});
    }
  }

  Future<void> refresh(BuildContext context) async {
    await reload(debugSource: '$runtimeType#refresh');
    if (context.mounted) await context.read<BackupProvider>().recheck();
  }

  Future<void> changeYear(int newYear) async {
    if (year == newYear) return;

    _currentSearchFilter = currentSearchFilter.copyWith(years: {newYear});
    await reload(debugSource: '$runtimeType#changeYear $newYear');
    AnalyticsService.instance.logViewHome(year: year);
  }

  Future<void> goToViewPage(BuildContext context, StoryDbModel story) async {
    await ShowStoryRoute(id: story.id, story: story).push(context);
  }

  Future<void> goToFilter(BuildContext context, {bool save = false}) async {
    final result = await SearchFilterBottomSheet(
      params: SearchFilterRoute(
        initialTune: currentSearchFilter,
        resetTune: initialSearchFilter,
        multiSelectYear: false,
        filterTagModifiable: true,
        allowSaveSearchFilter: false,
      ),
    ).show(context: context);

    if (result is SearchFilterObject) {
      _currentSearchFilter = result;
      await reload(debugSource: '$runtimeType#goToFilter');
    }
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditStoryRoute(
      id: null,
      initialYear: year,
      initialTagId: filteredTagId,
    ).push(context);
    await reload(debugSource: '$runtimeType#goToNewPage');

    // https://developer.android.com/guide/playcore/in-app-review#when-to-request
    // https://developer.apple.com/app-store/ratings-and-reviews/
    int newCount = await NewStoriesCountStorage().increase();
    if (newCount % 10 == 0) InAppReviewService.request();
  }

  Future<void> openEndDrawer(BuildContext context) async {
    AnalyticsService.instance.logOpenHomeEndDrawer(year: year);
    Scaffold.of(context).openEndDrawer();
  }

  void changeName(BuildContext context) async {
    final result = await NicknameBottomSheet(nickname: nickname).show(context: context);
    if (result is String) {
      PreferenceDbModel.db.nickname.set(result);
      nickname = PreferenceDbModel.db.nickname.get();
      notifyListeners();
    }
  }

  void onAStoryReloaded(StoryDbModel updatedStory) {
    if (updatedStory.type != PathType.docs) {
      setStories(stories?.removeElement(updatedStory));
      debugPrint('🚧 Removed ${updatedStory.id}:${updatedStory.type.name} by $runtimeType#onChanged');
    } else {
      setStories(stories?.replaceElement(updatedStory));
      debugPrint('🚧 Updated ${updatedStory.id}:${updatedStory.type.name} contents by $runtimeType#onChanged');
    }

    scrollInfo.setupStoryKeys(stories?.items ?? []);
    notifyListeners();
  }

  @override
  void dispose() {
    scrollInfo.dispose();
    super.dispose();
  }
}
