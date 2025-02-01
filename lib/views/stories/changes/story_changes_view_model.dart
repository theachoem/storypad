import 'dart:math';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/views/stories/changes/story_changes_view.dart';
import 'package:storypad/core/services/story_db_constructor_service.dart';

class StoryChangesViewModel extends BaseViewModel {
  final StoryChangesRoute params;

  StoryChangesViewModel({
    required this.params,
  }) {
    load();
  }

  StoryDbModel? originalStory;
  StoryDbModel? draftStory;

  int get toBeRemovedCount {
    int originalChanges = originalStory?.allChanges?.length ?? 0;
    int draftChanges = draftStory?.allChanges?.length ?? 0;

    return max(0, originalChanges - draftChanges);
  }

  Future<void> load() async {
    originalStory = await StoryDbModel.db.find(params.id);

    originalStory = await originalStory?.loadAllChanges();
    draftStory = originalStory;

    if (originalStory != null) reloadIfInvalid();

    notifyListeners();
  }

  /// For old data before v2.2.3, changes is saved dublicated. In that case, save new original story which contains valid allChanges.
  /// This will be pass to [StoryDbConstructorService]
  Future<void> reloadIfInvalid() async {
    if (originalStory?.allChanges?.length != originalStory?.rawChanges?.length) {
      debugPrint(
        "$runtimeType#reloadIfInvalid valid: ${originalStory?.allChanges?.length}; raw: ${originalStory?.rawChanges?.length}",
      );
      await StoryDbModel.db.set(originalStory!);
    }
  }

  void draftRemove(StoryContentDbModel change) {
    List<StoryContentDbModel>? newChanges = draftStory!.allChanges?.toList()
      ?..removeWhere((item) => item.id == change.id);
    draftStory = draftStory?.copyWith(allChanges: newChanges);
    notifyListeners();
  }

  void cancel() {
    draftStory = originalStory;
    notifyListeners();
  }

  Future<void> restore(BuildContext context, StoryContentDbModel change) async {
    draftStory = draftStory?.copyWith(allChanges: [
      ...draftStory!.allChanges!,
      StoryContentDbModel.dublicate(change),
    ]);

    await StoryDbModel.db.set(draftStory!);
    await load();

    AnalyticsService.instance.logRestoreStoryChange(
      story: draftStory!,
    );

    if (context.mounted) MessengerService.of(context).showSnackBar("Restored");
  }

  Future<void> remove(BuildContext context) async {
    OkCancelResult resuilt = await showOkCancelAlertDialog(
      context: context,
      title: "Are you sure to delete these changes?",
      message: "You can't undo this action.",
    );

    if (resuilt == OkCancelResult.ok) {
      await StoryDbModel.db.set(draftStory!);
      await load();

      AnalyticsService.instance.logRemoveStoryChanges(
        story: draftStory!,
      );
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (toBeRemovedCount > 0) {
      OkCancelResult result = await showOkCancelAlertDialog(context: context, title: "Are you to discard changes?");
      shouldPop = result == OkCancelResult.ok;
    }

    if (shouldPop && context.mounted) Navigator.of(context).pop(result);
  }
}
