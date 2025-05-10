import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/mixins/list_reorderable.dart';
import 'package:storypad/core/services/stories/story_content_to_quill_controllers_service.dart';
import 'package:storypad/core/services/stories/story_has_changed_service.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_managable.dart';
import 'package:storypad/widgets/sp_story_labels.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

class ShowStoryViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback, StoryPagesManagable {
  final ShowStoryRoute params;

  ShowStoryViewModel({
    required this.params,
    required BuildContext context,
  }) {
    pageController = PageController();
    pageController.addListener(() {
      currentPageNotifier.value = pageController.page!;
    });

    load(params.id, initialStory: params.story);
  }

  StoryDbModel? story;
  StoryContentDbModel? draftContent;
  TextSelection? currentTextSelection;

  Future<void> load(
    int id, {
    StoryDbModel? initialStory,
  }) async {
    story = initialStory ?? await StoryDbModel.db.find(id);
    draftContent = story!.generateDraftContent();

    bool alreadyHasPage = draftContent?.richPages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent!.addRichPage();

    quillControllers = await StoryContentToQuillControllersService.call(draftContent!, readOnly: true);
    setupControllers();
    notifyListeners();
  }

  void setupControllers() {
    focusNodes = [];
    scrollControllers = [];
    titleControllers = [];

    for (int i = 0; i < quillControllers.length; i++) {
      focusNodes.add(FocusNode());
      scrollControllers.add(ScrollController());
      titleControllers
          .add(TextEditingController(text: draftContent?.richPages?[i].title)..addListener(() => _silentlySave()));
      quillControllers[i].addListener(() => _silentlySave());
    }
  }

  @override
  Future<void> addPage() async {
    draftContent = draftContent!.addRichPage();
    _silentlySave();

    scrollControllers.add(ScrollController());
    focusNodes.add(FocusNode());
    titleControllers.add(TextEditingController()..addListener(() => _silentlySave()));
    quillControllers.add(QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
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
    await StoryDbModel.db.set(story!);
    notifyListeners();

    AnalyticsService.instance.logSetTagsToStory(
      story: story!,
    );

    return true;
  }

  Future<void> setFeeling(String? feeling) async {
    story = story!.copyWith(updatedAt: DateTime.now(), feeling: feeling);
    notifyListeners();
    await StoryDbModel.db.set(story!);

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
    await StoryDbModel.db.set(story!);

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
    await StoryDbModel.db.set(story!);

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
    await StoryDbModel.db.set(story!);

    AnalyticsService.instance.logToggleShowTime(
      story: story!,
    );
  }

  Future<void> changePreferences(StoryPreferencesDbModel preferences) async {
    story = story!.copyWith(updatedAt: DateTime.now(), preferences: preferences);
    notifyListeners();

    await StoryDbModel.db.set(story!);

    AnalyticsService.instance.logUpdateStoryPreferences(
      story: story!,
    );
  }

  SpStoryLabelsDraftActions getDraftActions(BuildContext context) {
    return SpStoryLabelsDraftActions(
      onContinueEditing: () => goToEditPage(context),
      onDiscardDraft: () async {
        OkCancelResult result = await showOkCancelAlertDialog(
          context: context,
          isDestructiveAction: true,
          title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
          okLabel: tr("button.discard"),
        );

        if (result == OkCancelResult.ok) {
          await StoryDbModel.db.set(story!.copyWith(draftContent: null));
          await load(story!.id);
        }
      },
      onViewPrevious: () async {
        await ShowChangeRoute(content: story!.latestContent!).push(context);
        await load(story!.id);
      },
    );
  }

  Future<void> goToEditPage(BuildContext context) async {
    if (draftContent == null || draftContent?.richPages == null || pageController.page == null) return;

    int? currentPageIndex;

    await EditStoryRoute(
      id: story!.id,
      initialPageIndex: currentPage,
      quillControllers: quillControllers,
      story: story,
      onPageIndexChanged: (page) => currentPageIndex = page,
    ).push(context);

    await load(story!.id);

    if (currentPageIndex != null && pageController.hasClients) {
      pageController.jumpToPage(currentPageIndex!);
    }
  }

  void _silentlySave({
    bool draft = true,
  }) {
    debouncedCallback(() async {
      if (await _getHasChange()) {
        story = await StoryDbModel.fromShowPage(this, draft: draft);
        await StoryDbModel.db.set(story!);
        notifyListeners();
      }
    });
  }

  Future<bool> _getHasChange() async {
    return StoryHasChangedService.call(
      titleControllers: titleControllers,
      quillControllers: quillControllers,
      latestContent: story?.draftContent ?? story!.latestContent!,
      draftContent: draftContent!,
    );
  }
}
