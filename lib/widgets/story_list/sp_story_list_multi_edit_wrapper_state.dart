part of 'sp_story_list_multi_edit_wrapper.dart';

class SpStoryListMultiEditWrapperState extends ChangeNotifier {
  final bool disabled;

  SpStoryListMultiEditWrapperState({
    required this.disabled,
  });

  bool editing = false;
  Set<int> selectedStories = {};
  Set<int> stories = {};

  void toggleSelection(StoryDbModel story) {
    if (selectedStories.contains(story.id)) {
      selectedStories.remove(story.id);
    } else {
      selectedStories.add(story.id);
    }
    notifyListeners();
  }

  void turnOnEditing({
    int? initialId,
  }) {
    editing = true;
    selectedStories.clear();
    if (initialId != null) selectedStories.add(initialId);
    notifyListeners();
  }

  void turnOffEditing({
    int? initialId,
  }) {
    editing = false;
    selectedStories.clear();
    notifyListeners();
  }

  void toggleSelectAll(BuildContext context) {
    if (selectedStories.length == stories.length) {
      selectedStories.clear();
    } else {
      selectedStories.addAll(stories);
    }
    notifyListeners();
  }

  Future<bool> putBackAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_put_back_these_stories.title"),
      okLabel: tr("button.put_back"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      for (int i = 0; i < selectedStories.length; i++) {
        int id = selectedStories.elementAt(i);
        final record = await StoryDbModel.db.find(id);
        await record?.putBack(runCallbacks: i == selectedStories.length - 1);
      }

      turnOffEditing();
      await HomeView.reload(debugSource: '$runtimeType#putBackAll');

      return true;
    }

    return false;
  }

  Future<bool> moveToBinAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_move_to_bin_these_stories.title"),
      isDestructiveAction: true,
      okLabel: tr("button.move_to_bin"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      for (int i = 0; i < selectedStories.length; i++) {
        int id = selectedStories.elementAt(i);
        final record = await StoryDbModel.db.find(id);
        await record?.moveToBin(runCallbacks: i == selectedStories.length - 1);
      }

      turnOffEditing();
      await HomeView.reload(debugSource: '$runtimeType#putBackAll');
      return true;
    }

    return false;
  }

  Future<bool> archiveAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_archive_these_stories.title"),
      okLabel: tr("button.archive"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      for (int i = 0; i < selectedStories.length; i++) {
        int id = selectedStories.elementAt(i);
        final record = await StoryDbModel.db.find(id);
        await record?.archive(runCallbacks: i == selectedStories.length - 1);
      }

      turnOffEditing();
      await HomeView.reload(debugSource: '$runtimeType#putBackAll');
      return true;
    }

    return false;
  }

  Future<bool> permanantDeleteAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_delete_these_stories.title"),
      message: tr("dialog.are_you_sure.you_cant_undo_message"),
      isDestructiveAction: true,
      okLabel: tr("button.permanent_delete"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      final state = SpStoryListMultiEditWrapper.of(context);

      for (int i = 0; i < state.selectedStories.length; i++) {
        int id = state.selectedStories.elementAt(i);
        await StoryDbModel.db.delete(id, runCallbacks: i == state.selectedStories.length - 1);
      }

      turnOffEditing();
      await HomeView.reload(debugSource: '$runtimeType#putBackAll');
      return true;
    }

    return false;
  }
}
