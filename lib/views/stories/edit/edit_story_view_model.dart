import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/concerns/schedule_concern.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/story_helper.dart';
import 'package:storypad/core/types/editing_flow_type.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';

class EditStoryViewModel extends BaseViewModel with ScheduleConcern {
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

  EditingFlowType? flowType;
  StoryDbModel? story;
  StoryContentDbModel? draftContent;

  Future<void> init({
    StoryDbModel? initialStory,
  }) async {
    if (params.id != null) story = initialStory ?? await StoryDbModel.db.find(params.id!);
    flowType = story == null ? EditingFlowType.create : EditingFlowType.update;

    story ??= StoryDbModel.fromDate(openedOn, initialYear: params.initialYear);
    draftContent = story?.latestChange != null
        ? StoryContentDbModel.dublicate(story!.latestChange!)
        : StoryContentDbModel.create(createdAt: openedOn);

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
      quillControllers = await StoryHelper.buildQuillControllers(
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
      StoryHelper.hasDataWrittenFromController(draftContent: draftContent!, quillControllers: quillControllers);

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

  Future<void> setDate(DateTime date) async {
    story = story!.copyWith(day: date.day, month: date.month, year: date.year);
    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logSetStoryFeeling(
      story: story!,
    );
  }

  Future<void> toggleShowDayCount() async {
    if (story == null) return;

    story = story!.copyWith(updatedAt: DateTime.now(), showDayCount: !story!.showDayCount);
    notifyListeners();

    if (await hasDataWritten) {
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }

    AnalyticsService.instance.logToggleShowDayCount(
      story: story!,
    );
  }

  void _silentlySave() {
    scheduleAction(() async {
      await save();
    });
  }

  Future<void> save() async {
    if (await _getHasChange()) {
      story = await StoryDbModel.fromDetailPage(this);
      await StoryDbModel.db.set(story!);
      lastSavedAtNotifier.value = story?.updatedAt;
    }
  }

  Future<bool> _getHasChange() async {
    return StoryHelper.hasChanges(
      draftContent: draftContent!,
      quillControllers: quillControllers,
      latestChange: story!.latestChange!,
      ignoredEmpty: flowType == EditingFlowType.update,
    );
  }

  @override
  void dispose() {
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
