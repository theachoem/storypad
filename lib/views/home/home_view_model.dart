import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/insert_file_to_db_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer_state.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';

part 'local_widgets/home_scroll_info.dart';
part 'local_widgets/home_scroll_app_bar_info.dart';

class HomeViewModel extends ChangeNotifier with DisposeAwareMixin {
  late final scrollInfo = _HomeScrollInfo(viewModel: () => this);

  HomeViewModel() {
    AnalyticsService.instance.logViewHome(year: year);
    reload(debugSource: 'HomeViewModel#_constructor');

    BackupRepository.appInstance.restoreService.addListener(_restoreServiceListener);
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

  void setStories(CollectionDbModel<StoryDbModel>? value, CollectionDbModel<StoryDbModel>? pinnedValue) {
    _stories = value?.deduplicateAndSort(
      comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
    );
    _pinnedStories = pinnedValue?.deduplicateAndSort(
      comparator: (a, b) => b.displayPathDate.compareTo(a.displayPathDate),
    );

    scrollInfo.setupStoryKeys(
      stories?.items ?? [],
      pinnedStories?.items ?? [],
    );
  }

  List<int> get months {
    List<int> months = stories?.items.map((e) => e.month).toSet().toList() ?? [];
    if (months.isEmpty) months.add(DateTime.now().month);
    return months;
  }

  Future<void> reload({
    required String debugSource,
  }) async {
    AppLogger.d('🚧 Reload home from $debugSource 🏠');

    final stories = await StoryDbModel.db.where(
      filters: SearchFilterObject(
        years: {year},
        types: {PathType.docs},
        pinned: false,
        tagId: null,
        assetId: null,
      ).toDatabaseFilter(),
    );

    final pinnedStories = await StoryDbModel.db.where(
      filters: SearchFilterObject(
        years: {year},
        types: {PathType.docs},
        pinned: true,
        tagId: null,
        assetId: null,
      ).toDatabaseFilter(),
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
                  tagId: null,
                  assetId: null,
                ).toDatabaseFilter(),
              )
              .then((e) => e?.items.map((e) => e.displayPathDate).toSet().toList())
        : null;

    setStories(stories, pinnedStories);
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

  void takePhoto(BuildContext context) async {
    return SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
        if (photo == null) return;

        AssetDbModel? asset = await InsertFileToDbService.insertImage(photo, await photo.readAsBytes());
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

    final allPinned = allStories.every((story) => story.pinned == true);
    final firstStoryId = allStories.first.id;

    if (allPinned) {
      await state.unpinAll(context);
    } else {
      int pinnedCount = pinnedStories?.items.length ?? 0;
      pinnedCount += state.selectedStories.length;

      if (pinnedCount >= 3) {
        MessengerService.of(context).showSnackBar(
          tr('snack_bar.pinned_limited_reach'),
          success: false,
        );
        return;
      }
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
      } else if (updatedStory.pinned == false) {
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
          setStories(
            stories?.removeElement(addedStory),
            pinnedCollection.exists(addedStory.id)
                ? pinnedCollection.replaceElement(addedStory)
                : pinnedCollection.addElement(addedStory, 0),
          );
        } else {
          final storiesCollection = stories ?? CollectionDbModel(items: []);
          setStories(
            storiesCollection.exists(addedStory.id)
                ? storiesCollection.replaceElement(addedStory)
                : storiesCollection.addElement(addedStory, 0),
            pinnedStories?.removeElement(addedStory),
          );
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
    BackupRepository.appInstance.restoreService.removeListener(_restoreServiceListener);
    super.dispose();
  }
}
