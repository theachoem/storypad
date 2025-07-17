part of '../sp_story_tile.dart';

class _StoryTileActions {
  final StoryDbModel story;
  final BuildContext listContext;

  _StoryTileActions({
    required this.story,
    required this.listContext,
  });

  Future<void> hardDelete(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: tr("dialog.are_you_sure_to_delete_this_story.title"),
      message: tr("dialog.are_you_sure.you_cant_undo_message"),
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

        /// In all case, delete button only show inside [SpStoryListWithQuery],
        /// So after undo, we should reload the list.
        if (listContext.mounted) SpStoryListWithQuery.of(listContext)?.load(debugSource: '$runtimeType#undoHardDelete');

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

    Future<void> undoMoveToBin(StoryDbModel originalStory) async {
      StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
      if (updatedStory == null) return;

      AnalyticsService.instance.logUndoMoveStoryToBin(
        story: updatedStory,
      );

      // sometime, it move to bin from archive page, so need to reload story list which in archives view as well.
      if (listContext.mounted) {
        await SpStoryListWithQuery.of(listContext)?.load(debugSource: '$runtimeType#undoMoveToBin');
      }

      return reloadHome('$runtimeType#undoMoveToBin');
    }

    if (context.mounted) {
      MessengerService.of(context).showSnackBar(
        tr("snack_bar.move_to_bin_success"),
        showAction: true,
        action: (foreground) {
          return SnackBarAction(
            label: tr("button.undo"),
            textColor: foreground,
            onPressed: () => undoMoveToBin(originalStory),
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

    await reloadHome('$runtimeType#putBack');

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
          await SpStoryListWithQuery.of(listContext)?.load(debugSource: '$runtimeType#undoPutBack');
          await reloadHome('$runtimeType#undoPutBack');
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
    StoryDbModel? updatedStory = await story.updatePreferences(
      preferences: story.preferences.copyWith(starIcon: starIcon),
    );

    if (updatedStory == null) return;

    AnalyticsService.instance.logUpdateStarIcon(
      story: updatedStory,
    );
  }

  Future<void> toggleShowDayCount() async {
    StoryDbModel? updatedStory = await story.updatePreferences(
      preferences: story.preferences.copyWith(showDayCount: !story.preferredShowDayCount),
    );

    if (updatedStory == null) return;

    AnalyticsService.instance.logToggleShowDayCount(
      story: updatedStory,
    );
  }

  Future<void> toggleShowTime() async {
    StoryDbModel? updatedStory = await story.updatePreferences(
      preferences: story.preferences.copyWith(showTime: !story.preferredShowTime),
    );

    if (updatedStory == null) return;

    AnalyticsService.instance.logToggleShowTime(
      story: updatedStory,
    );
  }

  Future<void> changeDate(DateTime newDateTime) async {
    final updatedStory = story.copyWith(
      year: newDateTime.year,
      month: newDateTime.month,
      day: newDateTime.day,
      hour: newDateTime.hour,
      minute: newDateTime.minute,
      second: newDateTime.second,
    );

    await StoryDbModel.db.set(updatedStory);

    AnalyticsService.instance.logChangeStoryDate(
      story: updatedStory,
    );
  }

  Future<void> reloadHome(String debugSource) async {
    await HomeView.reload(debugSource: debugSource);
  }
}
