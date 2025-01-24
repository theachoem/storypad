import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/concerns/schedule_concern.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/story_helper.dart';
import 'package:storypad/views/stories/changes/story_changes_view.dart';
import 'package:storypad/views/stories/edit/edit_story_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';

class ShowStoryViewModel extends BaseViewModel with ScheduleConcern {
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
  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);
  Map<int, QuillController> quillControllers = {};

  int get currentPage => currentPageNotifier.value.round();

  StoryDbModel? story;
  StoryContentDbModel? draftContent;
  TextSelection? currentTextSelection;

  Future<void> load(
    int id, {
    StoryDbModel? initialStory,
  }) async {
    story = initialStory ?? await StoryDbModel.db.find(id);

    draftContent = story?.latestChange != null
        ? StoryContentDbModel.dublicate(story!.latestChange!)
        : StoryContentDbModel.create(createdAt: DateTime.now());

    bool alreadyHasPage = draftContent?.pages?.isNotEmpty == true;
    if (!alreadyHasPage) draftContent = draftContent!..addPage();

    quillControllers = await StoryHelper.buildQuillControllers(draftContent!, readOnly: true);
    quillControllers.forEach((_, controller) {
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
    story = story!.copyWith(
      updatedAt: DateTime.now(),
      feeling: feeling,
    );
    StoryDbModel.db.set(story!);
    notifyListeners();
  }

  Future<void> renameTitle(BuildContext context) async {
    if (story == null || draftContent == null) return;

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
      draftContent = draftContent!.copyWith(title: result.first.trim());
      story = story!.copyWith(latestChange: draftContent!);

      StoryDbModel.db.set(story!);
      notifyListeners();
    }
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

  Future<void> goToChangesPage(BuildContext context) async {
    StoryChangesRoute(id: story!.id).push(context);
    await load(story!.id);
  }

  void _silentlySave() {
    scheduleAction(() async {
      if (await _getHasChange()) {
        story = await StoryDbModel.fromShowPage(this);
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
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPageNotifier.dispose();
    quillControllers.forEach((e, k) => k.dispose());
    lastSavedAtNotifier.dispose();
    super.dispose();
  }
}
