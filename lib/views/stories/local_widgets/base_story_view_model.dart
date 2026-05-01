import 'dart:math';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/stories/story_extract_assets_from_pages_service.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/views/templates/edit/edit_template_view.dart';

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

  bool get readOnly;

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

  Future<bool> setTags(List<int> tags, BuildContext context) async {
    final orderedTags = await _cleanTags(tags, context);
    story = story!.copyWith(updatedAt: DateTime.now(), tags: orderedTags.map((e) => e.toString()).toList());
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

  /// 1. Reorders tag IDs so emoji tags (categoryId != null) come first, sorted by
  /// their categoryId. Non-emoji tags follow after.
  ///
  /// 2. Ensure all tags exist.
  Future<List<int>> _cleanTags(List<int> tagIds, BuildContext context) async {
    if (tagIds.isEmpty) return tagIds;

    final emojiTags = context.read<TagsProvider>().emojiTags;
    final emojiTagMap = {for (var t in emojiTags?.items ?? []) t.id: t};

    final emojiTagIds = <int>[];
    final nonEmojiTagIds = <int>[];

    for (final id in tagIds) {
      if (emojiTagMap[id]?.categoryId != null) {
        emojiTagIds.add(id);
      } else {
        nonEmojiTagIds.add(id);
      }
    }

    emojiTagIds.sort((a, b) => (emojiTagMap[a]?.categoryId ?? 0).compareTo(emojiTagMap[b]?.categoryId ?? 0));
    final allTagIds = [...emojiTagIds, ...nonEmojiTagIds];

    return allTagIds.where(context.read<TagsProvider>().allTags!.items.map((t) => t.id).toSet().contains).toList();
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

  Future<void> setPlace(PlaceDbModel? place) async {
    story = story?.copyWith(updatedAt: DateTime.now(), place: place);
    notifyListeners();

    if (hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }
  }

  Future<void> addCurrentLocation() async {
    final result = await SpLocationService.fetchCurrentPlace();
    if (result != null) await setPlace(result);
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

  Future<void> saveAsTemplate(BuildContext context) async {
    if (story == null) return;

    if (!context.read<InAppPurchaseProvider>().isProUser) {
      const PaywallRoute(initialFocus: .templates).push(context);
      return;
    }

    var result = await EditTemplateRoute(
      flowType: .create,
      initialTemplate: TemplateDbModel.newTemplate(
        createdAt: DateTime.now(),
        content: story!.draftContent ?? story!.latestContent,
        galleryTemplateId: story!.galleryTemplateId,
        preferences: story?.preferences,
        tags: story!.validTags,
      ),
    ).push(context);

    if (result is TemplateDbModel) {
      story = story!.copyWith(templateId: result.id, updatedAt: DateTime.now());

      if (hasDataWritten) {
        await StoryDbModel.db.set(story!);
        lastSavedAtNotifier.value = story?.updatedAt;
      }

      AnalyticsService.instance.logSaveStoryAsTemplate(
        story: story!,
        template: result,
      );
    }
  }

  Future<void> addNewPage() async {
    HapticFeedback.selectionClick();

    draftContent = draftContent!.addRichPage();
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
    DateTime? updatedAt,
  }) {
    final assets = StoryExtractAssetsFromPagesService.call(draftContent?.richPages);

    debugPrint("Found assets: $assets in ${story?.id}");
    if (draft) {
      return story!.copyWith(
        updatedAt: updatedAt ?? DateTime.now(),
        latestContent: story?.latestContent ?? draftContent,
        draftContent: draftContent,
        assets: assets.toList(),
      );
    } else {
      return story!.copyWith(
        updatedAt: updatedAt ?? DateTime.now(),
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
