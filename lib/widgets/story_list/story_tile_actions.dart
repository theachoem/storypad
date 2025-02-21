import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/widgets/story_list/story_list_with_query.dart';

class StoryTileActions {
  final StoryDbModel story;
  final BuildContext listContext;

  StoryTileActions({
    required this.story,
    required this.listContext,
  });

  Future<void> hardDelete(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: tr("dialog.are_you_sure_to_delete_this_story.title"),
      message: tr("dialog.are_you_sure_to_delete_this_story.message"),
      okLabel: tr("button.delete"),
    );

    if (result == OkCancelResult.ok) {
      StoryDbModel originalStory = story.copyWith();
      await originalStory.delete();

      AnalyticsService.instance.logHardDeleteStory(
        story: originalStory,
      );

      if (!context.mounted) return;

      Future<void> undoHardDelete() async {
        StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
        if (updatedStory == null) return;

        /// In all case, delete button only show inside [StoryListWithQuery],
        /// So after undo, we should reload the list.
        if (listContext.mounted) StoryListWithQuery.of(listContext)?.load(debugSource: '$runtimeType#undoHardDelete');

        AnalyticsService.instance.logUndoHardDeleteStory(
          story: updatedStory,
        );
      }

      MessengerService.of(context).showSnackBar(
        tr("snack_bar.delete_success"),
        showAction: true,
        action: (foreground) {
          return SnackBarAction(
            label: tr("button.undo"),
            textColor: foreground,
            onPressed: () async => undoHardDelete(),
          );
        },
      );
    }
  }

  Future<void> importIndividualStory(BuildContext context) async {
    StoryDbModel originalStory = story.copyWith();
    StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
    if (updatedStory == null) return;

    AnalyticsService.instance.logImportIndividualStory(
      story: updatedStory,
    );

    if (!context.mounted) return;
    MessengerService.of(context).showSnackBar(tr("snack_bar.restore_individual_success"));
  }

  Future<void> moveToBin(BuildContext context) async {
    StoryDbModel originalStory = story.copyWith();
    StoryDbModel? updatedStory = await originalStory.moveToBin();
    if (updatedStory == null) return;

    AnalyticsService.instance.logMoveStoryToBin(
      story: updatedStory,
    );

    if (context.mounted) {
      MessengerService.of(context).showSnackBar(
        tr("snack_bar.move_to_bin_success"),
        showAction: true,
        action: (foreground) {
          return SnackBarAction(
            label: tr("button.undo"),
            textColor: foreground,
            onPressed: () async {
              StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
              if (updatedStory == null) return;

              AnalyticsService.instance.logUndoMoveStoryToBin(
                story: updatedStory,
              );

              // sometime, it move to bin from archive page, so need to reload story list which in archives view as well.
              if (listContext.mounted) {
                await StoryListWithQuery.of(listContext)?.load(debugSource: '$runtimeType#undoHardDelete');
              }

              return reloadHome('$runtimeType#moveToBin');
            },
          );
        },
      );
    }
  }

  Future<void> archive(BuildContext context) async {
    StoryDbModel originalStory = story.copyWith();
    StoryDbModel? updatedStory = await originalStory.archive();
    if (updatedStory == null) return;

    AnalyticsService.instance.logArchiveStory(
      story: updatedStory,
    );

    if (context.mounted) {
      MessengerService.of(context).showSnackBar(
        tr("snack_bar.archive_success"),
        showAction: true,
        action: (foreground) {
          return SnackBarAction(
            label: tr("button.undo"),
            textColor: foreground,
            onPressed: () async {
              StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
              if (updatedStory == null) return;

              AnalyticsService.instance.logUndoArchiveStory(
                story: updatedStory,
              );

              return reloadHome('$runtimeType#archive');
            },
          );
        },
      );
    }
  }

  Future<void> putBack(BuildContext context) async {
    StoryDbModel originalStory = story.copyWith();
    StoryDbModel? updatedStory = await originalStory.putBack();
    if (updatedStory == null) return;

    await reloadHome('$runtimeType#moveToBin');

    AnalyticsService.instance.logPutStoryBack(
      story: updatedStory,
    );

    if (listContext.mounted) {
      Future<void> undoPutBack(StoryDbModel originalStory) async {
        StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
        if (updatedStory == null) return;

        AnalyticsService.instance.logUndoPutBack(
          story: updatedStory,
        );

        if (listContext.mounted) {
          await StoryListWithQuery.of(listContext)?.load(debugSource: '$runtimeType#undoHardDelete');
          await reloadHome('$runtimeType#putBack');
        }
      }

      MessengerService.of(listContext).showSnackBar(
        tr("snack_bar.put_back_success"),
        showAction: true,
        action: (foreground) {
          return SnackBarAction(
            label: tr("button.undo"),
            textColor: foreground,
            onPressed: () => undoPutBack(originalStory),
          );
        },
      );
    }
  }

  Future<void> toggleStarred() async {
    StoryDbModel? updatedStory = await story.toggleStarred();
    if (updatedStory == null) return;

    AnalyticsService.instance.logToggleStoryStarred(
      story: updatedStory,
    );
  }

  Future<void> updateStarIcon(String starIcon) async {
    StoryDbModel? updatedStory = await story.updateStarIcon(starIcon: starIcon);
    if (updatedStory == null) return;

    AnalyticsService.instance.logUpdateStarIcon(
      story: updatedStory,
    );
  }

  Future<void> toggleShowDayCount() async {
    final updatedStory = story.copyWithPreferences(
      updatedAt: DateTime.now(),
      showDayCount: !story.showDayCount,
    );

    await StoryDbModel.db.set(updatedStory);

    AnalyticsService.instance.logToggleShowDayCount(
      story: updatedStory,
    );
  }

  Future<void> reloadHome(String debugSource) async {
    await listContext.read<HomeViewModel>().load(debugSource: debugSource);
  }
}
