import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/initializers/home_initializer.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/in_app_review_service.dart';
import 'package:storypad/core/services/restore_backup_service.dart';
import 'package:storypad/core/storages/new_stories_count_storage.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/home/local_widgets/nickname_bottom_sheet.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

part './local_widgets/home_scroll_info.dart';
part 'local_widgets/home_scroll_app_bar_info.dart';

class HomeViewModel extends BaseViewModel {
  late final scrollInfo = _HomeScrollInfo(viewModel: () => this);

  HomeViewModel({
    required BuildContext context,
  }) {
    AnalyticsService.instance.logViewHome(year: year);

    final initialData = HomeInitializer.getAndClear();

    if (initialData != null) {
      setStories(initialData.stories);
      nickname = initialData.nickname;
      initialData.legacyStorypadMigrationResponse?.showPendingMessage(context);
      if (nickname == null && context.mounted) showInputNameSheet(context);
    } else {
      reload(debugSource: 'HomeViewModel#_constructor');
    }

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

  Future<void> showInputNameSheet(BuildContext context) async {
    await Future.delayed(Durations.long3);
    if (context.mounted) changeName(context);
  }

  Future<void> reload({
    required String debugSource,
  }) async {
    debugPrint('🚧 Reload home from $debugSource 🏠');

    nickname = PreferenceDbModel.db.nickname.get();
    setStories(await StoryDbModel.db.where(filters: {
      'year': year,
      'types': [PathType.docs.name],
    }));

    notifyListeners();
  }

  Future<void> refresh(BuildContext context) async {
    await reload(debugSource: '$runtimeType#refresh');
    if (context.mounted) await context.read<BackupProvider>().recheck();
  }

  Future<void> changeYear(int newYear) async {
    if (year == newYear) return;

    year = newYear;
    setStories(null);
    notifyListeners();

    await reload(debugSource: '$runtimeType#changeYear $newYear');
    AnalyticsService.instance.logViewHome(year: year);
  }

  Future<void> goToViewPage(BuildContext context, StoryDbModel story) async {
    await ShowStoryRoute(id: story.id, story: story).push(context);
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditStoryRoute(id: null, initialYear: year).push(context);
    await reload(debugSource: '$runtimeType#goToNewPage');

    // https://developer.android.com/guide/playcore/in-app-review#when-to-request
    // https://developer.apple.com/app-store/ratings-and-reviews/
    int newCount = await NewStoriesCountStorage().increase();
    if (newCount % 10 == 0) InAppReviewService.request();
  }

  void changeName(BuildContext context) async {
    dynamic result = await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(curve: Curves.fastEaseInToSlowEaseOut, duration: Durations.long4),
      isScrollControlled: true,
      builder: (context) {
        return NicknameBottomSheet(nickname: nickname);
      },
    );

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
