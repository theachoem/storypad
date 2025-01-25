// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/story_list/story_list.dart';

class StoryTile extends StatelessWidget {
  static const double monogramSize = 32;

  const StoryTile({
    super.key,
    required this.story,
    required this.showMonogram,
    required this.onTap,
    required this.listContext,
    this.viewOnly = false,
  });

  final StoryDbModel story;
  final bool showMonogram;
  final bool viewOnly;
  final void Function()? onTap;

  /// In some case, StoryTile is removed from screen, which make its context unusable.
  /// [listContext] is still mounted even after story is removed, allow us it to read HomeViewModel & do other thiings.
  final BuildContext listContext;

  Future<void> hardDelete(BuildContext context) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: "Are you sure to delete this story?",
      message: "You can't undo this action",
      okLabel: "Delete",
    );

    if (result == OkCancelResult.ok) {
      StoryDbModel originalStory = story.copyWith();
      await originalStory.delete();

      AnalyticsService.instance.logHardDeleteStory(
        story: originalStory,
      );

      if (!context.mounted) return;

      MessengerService.of(context).showSnackBar(
        'Deleted successfully',
        showAction: true,
        action: (foreground) {
          return SnackBarAction(
            label: 'Undo',
            textColor: foreground,
            onPressed: () async {
              StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
              if (updatedStory == null) return;

              /// In all case, delete button only show inside [StoryListWithQuery],
              /// So after undo, we should reload the list.
              if (listContext.mounted) StoryListWithQuery.of(listContext)?.load();

              AnalyticsService.instance.logUndoHardDeleteStory(
                story: updatedStory,
              );
            },
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
    MessengerService.of(context).showSnackBar('Story restored!');
  }

  Future<void> moveToBin(BuildContext context) async {
    StoryDbModel originalStory = story.copyWith();
    StoryDbModel? updatedStory = await originalStory.moveToBin();
    if (updatedStory == null) return;

    AnalyticsService.instance.logMoveStoryToBin(
      story: updatedStory,
    );

    if (context.mounted) {
      MessengerService.of(context).showSnackBar("Moved to bin!", showAction: true, action: (foreground) {
        return SnackBarAction(
          label: "Undo",
          textColor: foreground,
          onPressed: () async {
            StoryDbModel? updatedStory = await StoryDbModel.db.set(originalStory);
            if (updatedStory == null) return;

            AnalyticsService.instance.logUndoMoveStoryToBin(
              story: updatedStory,
            );

            return reloadHome('$runtimeType#moveToBin');
          },
        );
      });
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
      MessengerService.of(context).showSnackBar("Archived!", showAction: true, action: (foreground) {
        return SnackBarAction(
          label: "Undo",
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
      });
    }
  }

  Future<void> putBack(BuildContext context) async {
    StoryDbModel originalStory = story.copyWith();
    StoryDbModel? updatedStory = await originalStory.putBack();
    if (updatedStory == null) return;

    AnalyticsService.instance.logPutStoryBack(
      story: updatedStory,
    );

    // put back most likely inside archives page (not home)
    // reload home as the put back data could go there.
    await reloadHome('$runtimeType#putBack');
  }

  Future<void> changeDate(BuildContext context) async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 100 * 365)),
      currentDate: story.displayPathDate,
    );

    if (date != null) {
      StoryDbModel originalStory = story.copyWith();
      StoryDbModel? updatedStory = await originalStory.changePathDate(date);

      if (updatedStory == null) return;
      AnalyticsService.instance.logChangeStoryDate(
        story: updatedStory,
      );

      if (date.year != story.year) {
        // story has moved to another year which move out of home view as well -> need to reload.
        return reloadHome('$runtimeType#changeDate');
      }
    }
  }

  Future<void> toggleStarred() async {
    StoryDbModel? updatedStory = await story.toggleStarred();
    if (updatedStory == null) return;

    AnalyticsService.instance.logToggleStoryStarred(
      story: updatedStory,
    );
  }

  Future<void> showInfo(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Story Date'),
                subtitle: Text(DateFormatService.yMEd(story.displayPathDate)),
              ),
              if (story.movedToBinAt != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Moved to bin'),
                  subtitle: Text(DateFormatService.yMEd_jm(story.movedToBinAt!)),
                ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Updated'),
                subtitle: Text(DateFormatService.yMEd_jm(story.updatedAt)),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Created'),
                subtitle: Text(DateFormatService.yMEd_jm(story.createdAt)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> reloadHome(String debugSource) async {
    await listContext.read<HomeViewModel>().load(debugSource: debugSource);
  }

  @override
  Widget build(BuildContext context) {
    StoryContentDbModel? content = story.latestChange;

    bool hasTitle = content?.title?.trim().isNotEmpty == true;
    bool hasBody = content?.displayShortBody != null && content?.displayShortBody?.trim().isNotEmpty == true;

    List<SpPopMenuItem> menus = buildPopUpMenus(context);

    return Theme(
      // Remove theme wrapper here when this is fixed:
      // https://github.com/letsar/flutter_slidable/issues/512
      data: Theme.of(context).copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(iconColor: WidgetStatePropertyAll(ColorScheme.of(context).onPrimary)),
        ),
      ),
      child: Slidable(
        closeOnScroll: true,
        key: ValueKey(story.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: List.generate(menus.length, (index) {
            final menu = menus[index];
            return SlidableAction(
              icon: menu.leadingIconData,
              backgroundColor: menu.titleStyle?.color ?? ColorFromDayService(context: context).get(index + 1)!,
              foregroundColor: ColorScheme.of(context).onPrimary,
              onPressed: (context) => menu.onPressed?.call(),
            );
          }),
        ),
        child: SpPopupMenuButton(
          smartDx: true,
          dyGetter: (double dy) => dy + kToolbarHeight,
          items: (BuildContext context) => menus,
          builder: (openPopUpMenu) {
            return InkWell(
              onTap: onTap,
              onLongPress: menus.isNotEmpty ? openPopUpMenu : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16.0,
                      children: [
                        buildMonogram(context),
                        buildContents(hasTitle, content, context, hasBody),
                      ],
                    ),
                    buildStarredButton(context)
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<SpPopMenuItem> buildPopUpMenus(BuildContext context) {
    return [
      if (story.editable)
        SpPopMenuItem(
          title: 'Change Date',
          leadingIconData: Icons.calendar_month,
          onPressed: () => changeDate(context),
        ),
      if (story.putBackAble)
        SpPopMenuItem(
          title: 'Put back',
          leadingIconData: Icons.restore_from_trash,
          onPressed: () => putBack(context),
        ),
      if (story.archivable)
        SpPopMenuItem(
          title: 'Archive',
          leadingIconData: Icons.archive,
          onPressed: () => archive(context),
        ),
      if (story.canMoveToBin)
        SpPopMenuItem(
          title: 'Move to bin',
          leadingIconData: Icons.delete,
          titleStyle: TextStyle(color: ColorScheme.of(context).error),
          onPressed: () => moveToBin(context),
        ),
      if (story.hardDeletable)
        SpPopMenuItem(
          title: 'Delete',
          leadingIconData: Icons.delete,
          titleStyle: TextStyle(color: ColorScheme.of(context).error),
          onPressed: () => hardDelete(context),
        ),
      if (story.cloudViewing)
        SpPopMenuItem(
          title: 'Import',
          leadingIconData: Icons.restore_outlined,
          titleStyle: TextStyle(color: ColorScheme.of(context).primary),
          onPressed: () => importIndividualStory(context),
        ),
      SpPopMenuItem(
        title: 'Info',
        leadingIconData: Icons.info,
        onPressed: () => showInfo(context),
      )
    ];
  }

  Widget buildContents(bool hasTitle, StoryContentDbModel? content, BuildContext context, bool hasBody) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (hasTitle)
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: Text(
              content!.title!,
              style: TextTheme.of(context).titleMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (hasBody)
          Container(
            width: double.infinity,
            margin: hasTitle
                ? null
                : AppTheme.getDirectionValue(
                    context,
                    const EdgeInsets.only(left: 24.0),
                    const EdgeInsets.only(right: 24.0),
                  ),
            child: SpMarkdownBody(body: content!.displayShortBody!),
          ),
        if (story.inArchives)
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: TextTheme.of(context).labelMedium,
                children: const [
                  WidgetSpan(child: Icon(Icons.archive_outlined, size: 16.0), alignment: PlaceholderAlignment.middle),
                  TextSpan(text: ' Archived'),
                ],
              ),
            ),
          ),
        // if (story.inBins) buildAutoDeleteMessage(context)
      ]),
    );
  }

  Widget buildStarredButton(BuildContext context) {
    double x = -16.0 * 2 + 48.0;
    double y = 16.0 * 2 - 48.0;

    if (AppTheme.rtl(context)) {
      x = -16.0 * 2 + 16.0;
      y = 16.0 * 2 - 48.0;
    }

    return Positioned(
      left: AppTheme.getDirectionValue(context, 0.0, null),
      right: AppTheme.getDirectionValue(context, null, 0.0),
      child: Container(
        transform: Matrix4.identity()..translate(x, y),
        child: IconButton(
          tooltip: 'Star',
          padding: const EdgeInsets.all(16.0),
          isSelected: story.starred,
          iconSize: 18.0,
          onPressed: viewOnly ? null : () => toggleStarred(),
          selectedIcon: Icon(
            Icons.favorite,
            color: ColorScheme.of(context).error,
          ),
          icon: Icon(
            Icons.favorite_outline,
            color: Theme.of(context).dividerColor,
            applyTextScaling: true,
          ),
        ),
      ),
    );
  }

  Widget buildMonogram(BuildContext context) {
    if (!showMonogram) {
      return Container(
        width: monogramSize,
        margin: const EdgeInsets.only(top: 9.0, left: 0.5),
        alignment: Alignment.center,
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: ColorScheme.of(context).onSurface,
          ),
        ),
      );
    }

    return Column(
      spacing: 4.0,
      children: [
        Container(
          width: monogramSize,
          color: ColorScheme.of(context).surface.withValues(),
          child: Text(
            DateFormatService.E(story.displayPathDate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextTheme.of(context).labelMedium,
          ),
        ),
        Container(
          width: monogramSize,
          height: monogramSize,
          decoration: BoxDecoration(
            color: ColorFromDayService(context: context).get(story.displayPathDate.weekday),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            story.displayPathDate.day.toString(),
            style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).onPrimary),
          ),
        ),
      ],
    );
  }

  Widget buildAutoDeleteMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).error),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.info,
                size: 12.0,
                color: ColorScheme.of(context).error,
              ),
            ),
            TextSpan(
              text:
                  ' Auto delete on ${DateFormatService.yMd((story.movedToBinAt ?? story.updatedAt).add(const Duration(days: 30)))}',
            ),
          ],
        ),
      ),
    );
  }
}
