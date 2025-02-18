import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/widgets/story_list/story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'archives_view.dart';

class ArchivesViewModel extends BaseViewModel {
  final ArchivesRoute params;

  ArchivesViewModel({
    required this.params,
  });

  int editedKey = 0;
  PathType type = PathType.archives;

  void changeEditKey() {
    editedKey++;
    notifyListeners();
  }

  void setType(PathType type) {
    this.type = type;
    notifyListeners();
  }

  Future<void> permanantDeleteAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_delete_these_stories.title"),
      message: tr("dialog.are_you_sure_to_delete_these_stories.message"),
      isDestructiveAction: true,
      okLabel: tr("button.permanent_delete"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      final state = StoryListMultiEditWrapper.of(context);

      for (int i = 0; i < state.selectedStories.length; i++) {
        int id = state.selectedStories.elementAt(i);
        await StoryDbModel.db.delete(id, runCallbacks: i == state.selectedStories.length - 1);
      }

      state.turnOffEditing();
    }
  }

  Future<void> moveToBinAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_move_to_bin_these_stories.title"),
      okLabel: tr("button.move_to_bin"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      final state = StoryListMultiEditWrapper.of(context);

      for (int i = 0; i < state.selectedStories.length; i++) {
        int id = state.selectedStories.elementAt(i);
        final record = await StoryDbModel.db.find(id);
        await record?.moveToBin(runCallbacks: i == state.selectedStories.length - 1);
      }

      state.turnOffEditing();
    }
  }

  Future<void> putBackAll(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr("dialog.are_you_sure_to_put_back_these_stories.title"),
      okLabel: tr("button.put_back"),
    );

    if (result == OkCancelResult.ok && context.mounted) {
      final state = StoryListMultiEditWrapper.of(context);

      for (int i = 0; i < state.selectedStories.length; i++) {
        int id = state.selectedStories.elementAt(i);
        final record = await StoryDbModel.db.find(id);
        await record?.putBack(runCallbacks: i == state.selectedStories.length - 1);
      }

      state.turnOffEditing();
    }

    if (context.mounted) {
      await context.read<HomeViewModel>().load(debugSource: '$runtimeType#putBackAll');
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (StoryListMultiEditWrapper.of(context).selectedStories.isNotEmpty) {
      OkCancelResult result = await showOkCancelAlertDialog(
        context: context,
        title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
        okLabel: tr("button.discard"),
      );
      shouldPop = result == OkCancelResult.ok;
    }

    if (shouldPop && context.mounted) Navigator.of(context).pop(result);
  }
}
