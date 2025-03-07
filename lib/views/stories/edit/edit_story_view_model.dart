import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/stories/story_has_changed_service.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';
import 'package:storypad/core/services/stories/story_content_to_quill_controllers_service.dart';
import 'package:storypad/core/services/stories/story_should_revert_change_service.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';

class EditStoryViewModel extends BaseViewModel with DebounchedCallback {
  final EditStoryRoute params;

  EditStoryViewModel({
    required this.params,
  }) {
    init(initialStory: params.story);

    pageController = PageController(initialPage: params.initialPageIndex);
    pageController.addListener(() {
      currentPageNotifier.value = pageController.page!;
    });
  }

  late final PageController pageController;
  late final ValueNotifier<double> currentPageNotifier = ValueNotifier(params.initialPageIndex.toDouble());
  TextEditingController? titleController;
  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);

  Map<int, QuillController> quillControllers = {};
  Map<int, ScrollController> scrollControllers = {};
  Map<int, FocusNode> focusNodes = {};
  final DateTime openedOn = DateTime.now();

  int get currentPageIndex => pageController.page!.round().toInt();
  int get currentPage => currentPageNotifier.value.round();

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
    flowType = story == null ? EditingFlowType.create : EditingFlowType.update;

    story ??= StoryDbModel.fromDate(openedOn, initialYear: params.initialYear);
    draftContent = story!.generateDraftContent();

    titleController = TextEditingController(text: draftContent?.title)
      ..addListener(() {
        draftContent = draftContent?.copyWith(title: titleController?.text);
        _silentlySave();
      });

    bool alreadyHasPage = draftContent?.pages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent!..addPage();

    if (params.quillControllers != null) {
      for (int i = 0; i < params.quillControllers!.length; i++) {
        quillControllers[i] = QuillController(
          document: params.quillControllers![i]!.document,
          selection: params.quillControllers![i]!.selection,
        )..addListener(() => _silentlySave());
      }
    } else {
      quillControllers = await StoryContentToQuillControllersService.call(
        draftContent!,
        readOnly: false,
      );

      quillControllers.forEach((_, controller) {
        controller.addListener(() => _silentlySave());
      });
    }

    for (int i = 0; i < quillControllers.length; i++) {
      scrollControllers[i] = ScrollController();
      focusNodes[i] = FocusNode();
    }

    notifyListeners();
  }

  Future<bool> get hasDataWritten =>
      StoryHasDataWrittenService.callByController(draftContent: draftContent!, quillControllers: quillControllers);

  Future<bool> setTags(List<int> tags) async {
    story = story!.copyWith(updatedAt: DateTime.now(), tags: tags.toSet().map((e) => e.toString()).toList());
    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    return true;
  }

  Future<void> setFeeling(String? feeling) async {
    story = story!.copyWith(updatedAt: DateTime.now(), feeling: feeling);
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

    story = story!.copyWithPreferences(
      showDayCount: !story!.preferredShowDayCount,
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

    story = story!.copyWithPreferences(
      showTime: !story!.preferredShowTime,
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
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> revertIfNoChange() async {
    if (story == null || initialStory == null) return;
    if (story?.updatedAt == initialStory?.updatedAt) return;

    bool shouldRevert = await StoryShouldRevertChangeService.call(currentStory: story!, initialStory: initialStory!);
    if (shouldRevert) {
      debugPrint("Reverting story back... ${initialStory?.id}");

      story = initialStory;
      await StoryDbModel.db.set(initialStory!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, Object? result, BuildContext context) async {
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
      if (story?.id != null) {
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

    if (shouldPop && context.mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() async {
    titleController?.dispose();
    pageController.dispose();
    currentPageNotifier.dispose();
    quillControllers.forEach((e, k) => k.dispose());
    focusNodes.forEach((e, k) => k.dispose());
    scrollControllers.forEach((e, k) => k.dispose());
    lastSavedAtNotifier.dispose();
    super.dispose();
  }
}
