import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/core/services/quill_service.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_gradient_loading.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_story_labels.dart';
import 'package:storypad/widgets/story_list/story_tile_actions.dart';
import 'package:storypad/widgets/story_list/story_tile_info_sheet.dart';

part 'story_tile_images.dart';
part 'story_tile_monogram.dart';
part 'story_tile_favorite_button.dart';

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
      if (story.putBackAble)
        SpPopMenuItem(
          title: 'Put back',
          leadingIconData: Icons.restore_from_trash,
          onPressed: () => StoryTileActions(story: story, listContext: listContext).putBack(context),
        ),
      if (story.archivable)
        SpPopMenuItem(
          title: 'Archive',
          leadingIconData: Icons.archive,
          onPressed: () => StoryTileActions(story: story, listContext: listContext).archive(context),
        ),
      if (story.canMoveToBin)
        SpPopMenuItem(
          title: 'Move to bin',
          leadingIconData: Icons.delete,
          titleStyle: TextStyle(color: ColorScheme.of(context).error),
          onPressed: () => StoryTileActions(story: story, listContext: listContext).moveToBin(context),
        ),
      if (story.hardDeletable)
        SpPopMenuItem(
          title: 'Delete',
          leadingIconData: Icons.delete,
          titleStyle: TextStyle(color: ColorScheme.of(context).error),
          onPressed: () => StoryTileActions(story: story, listContext: listContext).hardDelete(context),
        ),
      if (story.cloudViewing)
        SpPopMenuItem(
          title: 'Import',
          leadingIconData: Icons.restore_outlined,
          titleStyle: TextStyle(color: ColorScheme.of(context).primary),
          onPressed: () => StoryTileActions(story: story, listContext: listContext).importIndividualStory(context),
        ),
      SpPopMenuItem(
        title: 'Info',
        leadingIconData: Icons.info,
        onPressed: () => StoryTileInfoSheet(story: story).show(context),
      )
    ];
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
                        _StoryTileMonogram(
                          showMonogram: showMonogram,
                          monogramSize: monogramSize,
                          story: story,
                        ),
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

  Widget buildContents(bool hasTitle, StoryContentDbModel? content, BuildContext context, bool hasBody) {
    final images = content != null ? QuillService.imagesFromContent(content) : null;

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
                ? EdgeInsets.only(top: MediaQuery.textScalerOf(context).scale(6.0))
                : AppTheme.getDirectionValue(
                    context,
                    const EdgeInsets.only(left: 24.0),
                    const EdgeInsets.only(right: 24.0),
                  ),
            child: SpMarkdownBody(body: content!.displayShortBody!),
          ),
        SpStoryLabels(
          story: story,
          fromStoryTile: true,
          margin: EdgeInsets.only(top: MediaQuery.textScalerOf(context).scale(8)),
          onToggleShowDayCount: viewOnly
              ? null
              : () async {
                  await StoryTileActions(story: story, listContext: listContext).toggleShowDayCount();
                  if (context.mounted) Navigator.maybePop(context);
                },
        ),
        if (images?.isNotEmpty == true) ...[
          SizedBox(height: MediaQuery.textScalerOf(context).scale(12)),
          _StoryTileImages(images: images!),
          if (story.inArchives) SizedBox(height: MediaQuery.textScalerOf(context).scale(4)),
        ],
        if (story.inArchives) ...[
          Container(
            margin: EdgeInsets.only(top: MediaQuery.textScalerOf(context).scale(8.0)),
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
        ]
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
        child: _StoryTileFavoriteButton(
          story: story,
          toggleStarred: viewOnly ? null : StoryTileActions(story: story, listContext: listContext).toggleStarred,
        ),
      ),
    );
  }
}
