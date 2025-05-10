import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/mixins/list_reorderable.dart';
import 'package:storypad/core/services/stories/story_has_changed_service.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';
import 'package:storypad/core/services/stories/story_content_to_quill_controllers_service.dart';
import 'package:storypad/core/services/stories/story_should_revert_change_service.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_managable.dart';

class EditStoryViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback, StoryPagesManagable {
  final EditStoryRoute params;

  @override
  bool get canEditPages => true;

  EditStoryViewModel({
    required this.params,
  }) {
    init(initialStory: params.story);

    pageController = PageController(initialPage: params.initialPageIndex);
    currentPageNotifier.value = params.initialPageIndex.toDouble();
    pageController.addListener(() {
      currentPageNotifier.value = pageController.page!;
      params.onPageIndexChanged?.call(currentPage);
    });
  }

  final DateTime openedOn = DateTime.now();

  late final EditingFlowType flowType;
  StoryDbModel? story;
  StoryContentDbModel? draftContent;

  // for for compare if after user edit end up same paragraph,
  // we need to revert back.
  StoryDbModel? initialStory;

  Future<void> init({
    StoryDbModel? initialStory,
  }) async {
    if (params.id != null) story = this.initialStory = initialStory ?? await StoryDbModel.db.find(params.id!);
    if (story?.draftContent != null) lastSavedAtNotifier.value = story?.updatedAt;

    flowType = story == null ? EditingFlowType.create : EditingFlowType.update;

    story ??= StoryDbModel.fromDate(
      openedOn,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
      initialTagId: params.initialTagId,
    );

    draftContent = story!.generateDraftContent();

    bool alreadyHasPage = draftContent?.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent!.addRichPage();

    quillControllers = await StoryContentToQuillControllersService.call(
      draftContent!,
      readOnly: false,
      existingControllers: params.quillControllers,
    );

    setupControllers();
    notifyListeners();
  }

  void setupControllers() {
    focusNodes = [];
    titleFocusNodes = [];
    scrollControllers = [];
    titleControllers = [];

    for (int i = 0; i < quillControllers.length; i++) {
      focusNodes.add(FocusNode());
      titleFocusNodes.add(FocusNode());
      scrollControllers.add(ScrollController());
      titleControllers
          .add(TextEditingController(text: draftContent?.richPages?[i].title)..addListener(() => _silentlySave()));
      quillControllers[i].addListener(() => _silentlySave());
    }
  }

  Future<bool> get hasDataWritten => StoryHasDataWrittenService.callByController(
        draftContent: draftContent!,
        quillControllers: quillControllers,
        titleControllers: titleControllers,
      );

  @override
  Future<void> addPage() async {
    draftContent = draftContent!.addRichPage();
    _silentlySave();

    scrollControllers.add(ScrollController());
    focusNodes.add(FocusNode());
    titleFocusNodes.add(FocusNode());
    titleControllers.add(TextEditingController()..addListener(() => _silentlySave()));
    quillControllers.add(QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: false,
    )..addListener(() => _silentlySave()));

    notifyListeners();

    AnalyticsService.instance.logAddStoryPage(
      story: story!,
    );
  }

  @override
  Future<void> deletePage(int index) async {
    if (!canDeletePage) return;

    draftContent = draftContent?.removeRichPageAt(index);
    _silentlySave();

    quillControllers = [];
    focusNodes = [];
    titleFocusNodes = [];
    scrollControllers = [];
    titleControllers = [];

    quillControllers = await StoryContentToQuillControllersService.call(draftContent!, readOnly: false);
    setupControllers();

    notifyListeners();

    AnalyticsService.instance.logDeleteStoryPage(
      story: story!,
    );
  }

  @override
  void reorderPages({
    required int oldIndex,
    required int newIndex,
  }) {
    quillControllers = quillControllers.reorder(oldIndex: oldIndex, newIndex: newIndex);
    focusNodes = focusNodes.reorder(oldIndex: oldIndex, newIndex: newIndex);
    titleFocusNodes = titleFocusNodes.reorder(oldIndex: oldIndex, newIndex: newIndex);
    scrollControllers = scrollControllers.reorder(oldIndex: oldIndex, newIndex: newIndex);
    titleControllers = titleControllers.reorder(oldIndex: oldIndex, newIndex: newIndex);
    _silentlySave();

    notifyListeners();

    AnalyticsService.instance.logReorderStoryPages(
      story: story!,
    );
  }

  Future<bool> setTags(List<int> tags) async {
    story = story!.copyWith(updatedAt: DateTime.now(), tags: tags.toSet().map((e) => e.toString()).toList());
    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logSetTagsToStory(
      story: story!,
    );

    return true;
  }

  Future<void> setFeeling(String? feeling) async {
    story = story?.copyWith(updatedAt: DateTime.now(), feeling: feeling);
    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logSetStoryFeeling(
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
    );

    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logChangeStoryDate(
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

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logToggleShowDayCount(
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

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logToggleShowTime(
      story: story!,
    );
  }

  Future<void> changePreferences(StoryPreferencesDbModel preferences) async {
    story = story!.copyWith(updatedAt: DateTime.now(), preferences: preferences);
    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logUpdateStoryPreferences(
      story: story!,
    );
  }

  void _silentlySave() {
    debouncedCallback(() async {
      await draftSave();
    });
  }

  Future<void> draftSave() async {
    if (await _hasChange()) {
      story = await StoryDbModel.fromDetailPage(this, draft: true);
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }
  }

  Future<void> saveWithoutCheck() async {
    story = await StoryDbModel.fromDetailPage(this, draft: false);
    await StoryDbModel.db.set(story!);
    lastSavedAtNotifier.value = story?.updatedAt;
  }

  Future<bool> _hasChange() async {
    return StoryHasChangedService.call(
      titleControllers: titleControllers,
      quillControllers: quillControllers,
      latestContent: story?.draftContent ?? story!.latestContent!,
      draftContent: draftContent!,
      ignoredEmpty: flowType == EditingFlowType.update,
    );
  }

  Future<void> done(BuildContext context) async {
    // Re-save without check to make sure draft content is removed. We will revert back if no change anyway.
    await saveWithoutCheck();
    await revertIfNoChange();
    if (context.mounted) Navigator.maybePop(context, story);
  }

  Future<void> revertIfNoChange() async {
    bool shouldRevert = await StoryShouldRevertChangeService.call(currentStory: story, initialStory: initialStory);
    if (shouldRevert) {
      debugPrint("Reverting story back... ${initialStory?.id}");

      story = initialStory;
      await StoryDbModel.db.set(initialStory!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, Object? result, BuildContext context) async {
    if (managingPage) return toggleManagingPage();
    if (didPop) return;

    Future<OkCancelResult> showConfirmDialog(BuildContext context) async {
      return showOkCancelAlertDialog(
        context: context,
        isDestructiveAction: true,
        title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
        okLabel: tr("button.discard"),
      );
    }

    bool shouldPop = true;
    if (flowType == EditingFlowType.create) {
      if (lastSavedAtNotifier.value != null) {
        OkCancelResult result = await showConfirmDialog(context);
        if (result == OkCancelResult.ok) {
          await StoryDbModel.db.delete(story!.id);
          shouldPop = true;
        } else {
          shouldPop = false;
        }
      }
    } else if (flowType == EditingFlowType.update) {
      if (story?.updatedAt != initialStory?.updatedAt) {
        OkCancelResult result = await showConfirmDialog(context);
        if (result == OkCancelResult.ok) {
          await StoryDbModel.db.set(initialStory!);
          shouldPop = true;
        } else {
          shouldPop = false;
        }
      }
    }

    // if discard, just pop.
    if (shouldPop && context.mounted) Navigator.of(context).pop(null);
  }
}
