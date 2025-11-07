import 'dart:math';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/stories/story_extract_assets_from_pages_service.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';

part 'story_pages_manager_info.dart';

abstract class BaseStoryViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  StoryDbModel? story;
  StoryContentDbModel? draftContent;
  final DateTime openedOn = DateTime.now();

  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);
  late final StoryPagesManagerInfo pagesManager;

  BaseStoryViewModel({
    int? initialPageIndex,
    double initialPageScrollOffet = 0.0,
  }) {
    pagesManager = StoryPagesManagerInfo(
      initialPageIndex: initialPageIndex,
      initialScrollOffset: initialPageScrollOffet,
      draftContent: () => draftContent,
      notifyListeners: () => notifyListeners(),
    );
  }

  EditingFlowType get flowType => EditingFlowType.update;

  bool get hasDataWritten =>
      flowType == EditingFlowType.update || StoryHasDataWrittenService.callByContent(draftContent!);

  bool get hasChange {
    if (draftContent == null) return false;

    final latestContent = story?.draftContent ?? story?.latestContent;
    if (latestContent == null) return false;

    // when not ignore empty & no data written, consider not changed.
    if (flowType == EditingFlowType.create && !StoryHasDataWrittenService.callByContent(draftContent!)) return false;
    return draftContent!.hasChanges(latestContent);
  }

  Future<bool> setTags(List<int> tags) async {
    story = story!.copyWith(updatedAt: DateTime.now(), tags: tags.toSet().map((e) => e.toString()).toList());
    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logSetTagsToStory(
      story: story!,
    );

    return true;
  }

  Future<void> changePreferences(StoryPreferencesDbModel preferences) async {
    if (preferences.layoutType != story?.preferences.layoutType) {
      pagesManager.currentPageIndexNotifier.value = null;

      if (pagesManager.pageController.hasClients) pagesManager.pageController.jumpToPage(0);
      if (pagesManager.pageScrollController.hasClients) pagesManager.pageScrollController.jumpTo(0);
    }

    story = story!.copyWith(updatedAt: DateTime.now(), preferences: preferences);
    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logUpdateStoryPreferences(
      story: story!,
    );
  }

  Future<void> toggleShowTime() async {
    if (story == null) return;

    story = story!.copyWith(
      preferences: story!.preferences.copyWith(showTime: !story!.preferredShowTime),
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logToggleShowTime(
      story: story!,
    );
  }

  Future<void> setFeeling(String? feeling) async {
    story = story?.copyWith(updatedAt: DateTime.now(), feeling: feeling);
    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logSetStoryFeeling(
      story: story!,
    );
  }

  Future<void> toggleShowDayCount() async {
    if (story == null) return;

    story = story!.copyWith(
      preferences: story!.preferences.copyWith(showDayCount: !story!.preferredShowDayCount),
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logToggleShowDayCount(
      story: story!,
    );
  }

  Future<void> changeDate(DateTime date) async {
    story = story!.copyWith(
      year: date.year,
      month: date.month,
      day: date.day,
      hour: date.hour,
      minute: date.minute,
      second: date.second,
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logChangeStoryDate(
      story: story!,
    );
  }

  Future<void> addNewPage() async {
    HapticFeedback.selectionClick();

    draftContent = draftContent!.addRichPage(crossAxisCount: 2, mainAxisCount: 1);
    pagesManager.pagesMap.add(richPage: draftContent!.richPages!.last, readOnly: false);
    await saveDraft(debugSource: '$runtimeType#addNewPage');
    notifyListeners();

    if (pagesManager.pageScrollController.hasClients) {
      pagesManager.scrollToPage(draftContent!.richPages!.last.id);
    } else if (pagesManager.pageController.hasClients) {
      pagesManager.pageController.animateToPage(
        draftContent!.richPages!.length - 1,
        duration: Durations.long4,
        curve: Curves.fastLinearToSlowEaseIn,
      );
    }

    AnalyticsService.instance.logAddStoryPage(
      story: story!,
    );
  }

  Future<void> deleteAPage(BuildContext context, StoryPageDbModel richPage) async {
    if (!pagesManager.canDeletePage) return;

    final result = await showOkCancelAlertDialog(
      title: tr("dialog.are_you_sure_to_delete_this_page.title"),
      context: context,
      okLabel: tr("button.delete"),
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      draftContent = draftContent!.removeRichPage(richPage.id);
      pagesManager.pagesMap.remove(richPage.id);
      await saveDraft(debugSource: '$runtimeType#deleteAPage');
      notifyListeners();

      AnalyticsService.instance.logDeleteStoryPage(
        story: story!,
      );
    }
  }

  Future<void> reorderPages({
    required int oldIndex,
    required int newIndex,
  }) async {
    draftContent = draftContent?.reorder(oldIndex: oldIndex, newIndex: newIndex);

    await saveDraft(debugSource: '$runtimeType#reorderPages');
    notifyListeners();

    AnalyticsService.instance.logReorderStoryPages(
      story: story!,
    );

    if (!pagesManager.managingPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pagesManager.pageScrollController.hasClients) {
          pagesManager.scrollToPage(draftContent!.richPages![newIndex].id);
        }
      });
    }
  }

  Future<void> onPageChanged(StoryPageDbModel richPage) async {
    draftContent = draftContent!.replacePage(richPage);
    pagesManager.pagesMap[richPage.id]?.page = richPage;

    return debouncedCallback(() async {
      await saveDraft(debugSource: '$runtimeType#onPageChanged');
    });
  }

  Future<void> saveDraft({
    required String debugSource,
  }) async {
    if (hasChange) {
      if (kDebugMode) print('$runtimeType#saveDraft called from $debugSource');
      story = buildStory(draft: true);
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story!.updatedAt;
    }
  }

  StoryDbModel buildStory({
    bool draft = true,
  }) {
    final assets = StoryExtractAssetsFromPagesService.call(draftContent?.richPages);

    debugPrint("Found assets: $assets in ${story?.id}");
    if (draft) {
      return story!.copyWith(
        updatedAt: DateTime.now(),
        latestContent: story?.latestContent ?? draftContent,
        draftContent: draftContent,
        assets: assets.toList(),
      );
    } else {
      return story!.copyWith(
        updatedAt: DateTime.now(),
        latestContent: draftContent,
        draftContent: null,
        assets: assets.toList(),
      );
    }
  }

  @override
  void dispose() {
    lastSavedAtNotifier.dispose();
    pagesManager.dispose();
    super.dispose();
  }
}
