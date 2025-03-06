import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/stories/story_has_changed_service.dart';
import 'package:storypad/core/services/stories/story_content_to_quill_controllers_service.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';
import 'package:storypad/widgets/sp_story_labels.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

class ShowStoryViewModel extends BaseViewModel with DebounchedCallback {
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

  late final PageController pageController;
  final ValueNotifier<double> currentPageNotifier = ValueNotifier(0);
  Map<int, QuillController> quillControllers = {};
  Map<int, ScrollController> scrollControllers = {};

  int get currentPage => currentPageNotifier.value.round();

  StoryDbModel? story;
  StoryContentDbModel? draftContent;
  TextSelection? currentTextSelection;

  Future<void> load(
    int id, {
    StoryDbModel? initialStory,
  }) async {
    story = initialStory ?? await StoryDbModel.db.find(id);
    draftContent = story!.generateDraftContent();

    bool alreadyHasPage = draftContent?.pages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent!..addPage();

    quillControllers = await StoryContentToQuillControllersService.call(draftContent!, readOnly: true);
    quillControllers.forEach((key, controller) {
      scrollControllers[key] = ScrollController();
      controller.addListener(() => _silentlySave());
    });

    notifyListeners();
  }

  Future<bool> setTags(List<int> tags) async {
    story = story!.copyWith(updatedAt: DateTime.now(), tags: tags.toSet().map((e) => e.toString()).toList());
    await StoryDbModel.db.set(story!);
    notifyListeners();

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

    story = story!.copyWithPreferences(
      showDayCount: !story!.preferredShowDayCount,
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

    story = story!.copyWithPreferences(
      showTime: !story!.preferredShowTime,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    await StoryDbModel.db.set(story!);

    AnalyticsService.instance.logToggleShowTime(
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
    if (draftContent == null || draftContent?.pages == null || pageController.page == null) return;

    await EditStoryRoute(
      id: story!.id,
      initialPageIndex: currentPage,
      quillControllers: quillControllers,
      story: story,
    ).push(context, rootNavigator: true);

    await load(story!.id);
  }

  void _silentlySave() {
    debouncedCallback(() async {
      if (await _getHasChange()) {
        story = await StoryDbModel.fromShowPage(this, draft: true);
        await StoryDbModel.db.set(story!);
        notifyListeners();
      }
    });
  }

  Future<bool> _getHasChange() async {
    return StoryHasChangedService.call(
      quillControllers: quillControllers,
      latestContent: story?.draftContent ?? story!.latestContent!,
      draftContent: draftContent!,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPageNotifier.dispose();
    quillControllers.forEach((e, k) => k.dispose());
    scrollControllers.forEach((e, k) => k.dispose());
    super.dispose();
  }
}
