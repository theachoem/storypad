import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/core/services/quill_service.dart';
import 'package:storypad/widgets/custom_embed/sp_image.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_story_labels.dart';
import 'package:storypad/widgets/story_list/story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/story_list/story_tile_actions.dart';
import 'package:storypad/widgets/story_list/story_info_sheet.dart';

part 'story_tile_images.dart';
part 'story_tile_monogram.dart';
part 'story_tile_favorite_button.dart';
part 'story_tile_contents.dart';

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

  List<SpPopMenuItem> buildPopUpMenus(BuildContext context) {
    return [
      if (story.inArchives || story.inBins && onTap != null)
        SpPopMenuItem(
          title: tr('button.open'),
          leadingIconData: Icons.library_books,
          onPressed: onTap,
        ),
      if (story.putBackAble)
        SpPopMenuItem(
          title: tr('button.put_back'),
          leadingIconData: Icons.settings_backup_restore,
          onPressed: () => StoryTileActions(story: story, listContext: listContext).putBack(context),
        ),
      if (story.archivable)
        SpPopMenuItem(
          title: tr('button.archive'),
          leadingIconData: Icons.archive,
          onPressed: () => StoryTileActions(story: story, listContext: listContext).archive(context),
        ),
      if (story.canMoveToBin)
        SpPopMenuItem(
          title: tr('button.move_to_bin'),
          leadingIconData: Icons.delete,
          titleStyle: TextStyle(color: ColorScheme.of(context).error),
          onPressed: () => StoryTileActions(story: story, listContext: listContext).moveToBin(context),
        ),
      if (story.hardDeletable)
        SpPopMenuItem(
          title: tr('button.permanent_delete'),
          leadingIconData: Icons.delete_forever,
          titleStyle: TextStyle(color: ColorScheme.of(context).error),
          onPressed: () => StoryTileActions(story: story, listContext: listContext).hardDelete(context),
        ),
      if (story.cloudViewing)
        SpPopMenuItem(
          title: tr('button.import'),
          leadingIconData: Icons.restore_outlined,
          titleStyle: TextStyle(color: ColorScheme.of(context).primary),
          onPressed: () => StoryTileActions(story: story, listContext: listContext).importIndividualStory(context),
        ),
      SpPopMenuItem(
        title: tr('button.info'),
        leadingIconData: Icons.info,
        onPressed: () => StoryInfoSheet(story: story).show(context),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (story.inArchives || story.inBins) {
      return StoryListMultiEditWrapper.tryListen(
        context: context,
        builder: (context, multiEditState) {
          if (multiEditState == null) return buildStoryTile(context);
          return buildStoryTile(context, multiEditState);
        },
      );
    }

    return buildStoryTile(context);
  }

  Widget buildStoryTile(
    BuildContext context, [
    StoryListMultiEditWrapperState? multiEditState,
  ]) {
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
        enabled: !story.inArchives && !story.inBins,
        closeOnScroll: true,
        key: ValueKey(story.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: List.generate(menus.length, (index) {
            final menu = menus[index];

            return CustomSlidableAction(
              backgroundColor: index.isEven
                  ? ColorScheme.of(context).readOnly.surface1!
                  : ColorScheme.of(context).readOnly.surface3!,
              foregroundColor: menu.titleStyle?.color,
              onPressed: null,
              padding: EdgeInsets.zero,
              child: Tooltip(
                message: menu.title,
                child: IconButton(
                  onPressed: () => menu.onPressed?.call(),
                  icon: Icon(menu.leadingIconData, color: menu.titleStyle?.color),
                ),
              ),
            );
          }),
        ),
        child: SpPopupMenuButton(
          smartDx: true,
          dyGetter: (double dy) => dy + kToolbarHeight,
          items: (BuildContext context) => menus,
          builder: (openPopUpMenu) {
            void Function()? onTap;
            void Function()? onLongPress;

            if (multiEditState?.editing == true) {
              onTap = () => multiEditState!.toggleSelection(story);
              onLongPress = null;
            } else if (story.inArchives || story.inBins) {
              onTap = () => openPopUpMenu.call();
              onLongPress = multiEditState != null && !multiEditState.editing
                  ? () => multiEditState.turnOnEditing(initialId: story.id)
                  : null;
            } else {
              onTap = this.onTap;
              onLongPress = () => openPopUpMenu.call();
            }

            return InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16.0,
                      children: [
                        _StoryTileMonogram(
                          showMonogram: showMonogram,
                          monogramSize: monogramSize,
                          story: story,
                        ),
                        _StoryTileContents(
                          story: story,
                          viewOnly: viewOnly,
                          listContext: listContext,
                          hasTitle: hasTitle,
                          content: content,
                          hasBody: hasBody,
                        ),
                      ],
                    ),
                    _StoryTileStarredButton(
                      story: story,
                      viewOnly: viewOnly,
                      listContext: listContext,
                      multiEditState: multiEditState,
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StoryTileStarredButton extends StatelessWidget {
  const _StoryTileStarredButton({
    required this.story,
    required this.viewOnly,
    required this.listContext,
    required this.multiEditState,
  });

  final StoryDbModel story;
  final bool viewOnly;
  final BuildContext listContext;
  final StoryListMultiEditWrapperState? multiEditState;

  @override
  Widget build(BuildContext context) {
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
        child: _StoryTileFavoriteButton(
          story: story,
          toggleStarred: viewOnly ? null : StoryTileActions(story: story, listContext: listContext).toggleStarred,
          multiEditState: multiEditState,
        ),
      ),
    );
  }
}
