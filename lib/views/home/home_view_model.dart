import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/in_app_review_service.dart';
import 'package:storypad/core/services/backups/restore_backup_service.dart';
import 'package:storypad/core/storages/new_stories_count_storage.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/discover/discover_view.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer_state.dart';
import 'package:storypad/widgets/bottom_sheets/sp_discover_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_nickname_bottom_sheet.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

part 'local_widgets/home_scroll_info.dart';
part 'local_widgets/home_scroll_app_bar_info.dart';

class HomeViewModel extends ChangeNotifier with DisposeAwareMixin {
  late final scrollInfo = _HomeScrollInfo(viewModel: () => this);

  HomeViewModel({
    required BuildContext context,
  }) {
    nickname = PreferenceDbModel.db.nickname.get();

    AnalyticsService.instance.logViewHome(year: year);
    reload(debugSource: 'HomeViewModel#_constructor');

    RestoreBackupService.instance.addListener(() async {
      reload(debugSource: '$runtimeType#_listenToRestoreService');
    });
  }

  String? nickname;
  int year = DateTime.now().year;

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

  Future<void> reload({
    required String debugSource,
  }) async {
    debugPrint('🚧 Reload home from $debugSource 🏠');

    nickname = PreferenceDbModel.db.nickname.get();
    final stories = await StoryDbModel.db.where(
      filters: SearchFilterObject(
        years: {year},
        types: {PathType.docs},
        tagId: null,
        assetId: null,
      ).toDatabaseFilter(),
    );

    setStories(stories);
    notifyListeners();
  }

  void onboard() {
    nickname = PreferenceDbModel.db.nickname.get();
    notifyListeners();
  }

  Future<void> refresh(BuildContext context) async {
    await reload(debugSource: '$runtimeType#refresh');

    // no need to wait because home app bar already show loading UI during syning.
    if (context.mounted) context.read<BackupProvider>().recheckAndSync();
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
    }
  }

  Future<void> goToNewPage(BuildContext context) async {
    final addedStory = await EditStoryRoute(
      id: null,
      initialYear: year,
    ).push(context);

    if (stories != null && addedStory is StoryDbModel) {
      if (year == addedStory.year) {
        int index = 0;

        // 1-1-2022 3pm: 0
        // 1-1-2022 12pm: 1
        // 2-1-2022 1am: 2
        // 3-1-2022 1am: 3
        //
        // added: 1-1-2022 2pm
        index = stories!.items.indexWhere((story) => addedStory.displayPathDate.isAfter(story.displayPathDate));

        // index possibly -1
        index = max(index, 0);

        setStories(stories!.addElement(addedStory, index));
      }

      year = addedStory.year;
      notifyListeners();
    }

    await reload(debugSource: '$runtimeType#goToNewPage');

    // https://developer.android.com/guide/playcore/in-app-review#when-to-request
    // https://developer.apple.com/app-store/ratings-and-reviews/
    int newCount = await NewStoriesCountStorage().increase();
    if (newCount % 10 == 0) InAppReviewService.request();
  }

  HomeEndDrawerState endDrawerState = HomeEndDrawerState.showSettings;
  Future<void> openSettings(BuildContext context) async {
    endDrawerState = HomeEndDrawerState.showSettings;
    AnalyticsService.instance.logOpenHomeEndDrawer(year: year);
    Scaffold.of(context).openEndDrawer();
  }

  Future<void> openYearsView(BuildContext context) async {
    endDrawerState = HomeEndDrawerState.showYearsView;
    AnalyticsService.instance.logOpenHomeEndDrawer(year: year);
    Scaffold.of(context).openEndDrawer();
  }

  void openDiscoverView(BuildContext context) {
    SpDiscoverSheet(
      params: DiscoverRoute(
        initialYear: year,
      ),
    ).show(context: context);
  }

  void changeName(BuildContext context) async {
    final result = await SpNicknameBottomSheet(nickname: nickname).show(context: context);
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
