import 'package:adaptive_dialog/adaptive_dialog.dart';
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
    load(initialStory: params.story);
  }

  late final PageController pageController = PageController(initialPage: params.initialPageIndex);
  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);

  Map<int, QuillController> quillControllers = {};
  final DateTime openedOn = DateTime.now();

  int get currentPageIndex => pageController.page!.round().toInt();

  EditingFlowType? flowType;
  StoryDbModel? story;
  StoryContentDbModel? draftContent;

  bool topToolbar = false;
  bool get showToolbarOnTop => quillControllers.isNotEmpty && topToolbar;
  bool get showToolbarOnBottom => quillControllers.isNotEmpty && !topToolbar;

  Future<void> load({
    StoryDbModel? initialStory,
  }) async {
    if (params.id != null) story = initialStory ?? await StoryDbModel.db.find(params.id!);
    flowType = story == null ? EditingFlowType.create : EditingFlowType.update;

    story ??= StoryDbModel.fromDate(openedOn, initialYear: params.initialYear);
    draftContent = story?.latestChange != null
        ? StoryContentDbModel.dublicate(story!.latestChange!)
        : StoryContentDbModel.create(createdAt: openedOn);

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

    notifyListeners();
  }

  void toggleToolbarPosition() {
    topToolbar = !topToolbar;
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

  void changeTitle(BuildContext context) async {
    List<String>? result = await showTextInputDialog(
      title: "Rename",
      context: context,
      textFields: [
        DialogTextField(
          initialText: draftContent?.title,
          maxLines: 2,
          hintText: 'Title...',
          validator: (value) {
            if (value == null || value.trim().isEmpty) return "Required";
            return null;
          },
        )
      ],
    );

    if (result != null && result.firstOrNull != null) {
      draftContent = draftContent!.copyWith(title: result.firstOrNull?.trim());
      notifyListeners();

      if (context.mounted) _silentlySave();
    }
  }

  void _silentlySave() {
    scheduleAction(() async {
      if (await _getHasChange()) {
        story = await StoryDbModel.fromDetailPage(this);
        await StoryDbModel.db.set(story!);

        lastSavedAtNotifier.value = story?.updatedAt;
      }
    });
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
    pageController.dispose();
    quillControllers.forEach((e, k) => k.dispose());
    lastSavedAtNotifier.dispose();
    super.dispose();
  }
}
