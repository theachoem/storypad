import 'dart:math';
import 'package:animated_clipper/animated_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/helpers/quill_context_menu_helper.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/objects/story_pages_block.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';
import 'package:storypad/core/services/stories/story_extract_image_from_content_service.dart';
import 'package:storypad/widgets/custom_embed/sp_date_block_embed.dart';
import 'package:storypad/widgets/custom_embed/sp_image_block_embed.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'package:storypad/widgets/sp_focus_node_builder2.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_quill_unknown_embed_builder.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 'story_page.dart';
part 'add_page_button.dart';
part 'more_vert_action_buttons.dart';
part 'title_field.dart';
part 'quill_editor.dart';

class StoryPageBuilderAction {
  final void Function(StoryPageDbModel newRichPage) onPageChanged;
  final void Function() onAddPage;
  final void Function(int oldIndex, int newIndex) onSwapPages;
  final void Function(StoryPageObject page) onDelete;

  final void Function(int pageIndex, StoryPageObject page, bool titleFocused, bool bodyFocused) onFocusChange;
  final bool canDeletePage;

  StoryPageBuilderAction({
    required this.onPageChanged,
    required this.onAddPage,
    required this.onSwapPages,
    required this.onDelete,
    required this.onFocusChange,
    required this.canDeletePage,
  });
}

class StoryPagesBuilder extends StatelessWidget {
  const StoryPagesBuilder({
    super.key,
    required this.preferences,
    required this.pages,
    required this.storyContent,
    this.onTitleVisibilityChanged,
    this.actions,
  });

  final StoryPreferencesDbModel? preferences;
  final StoryContentDbModel storyContent;
  final List<StoryPageObject> pages;
  final StoryPageBuilderAction? actions;
  final void Function(int pageIndex, StoryPageObject page, VisibilityInfo info)? onTitleVisibilityChanged;

  bool get readOnly => actions == null;

  double get spacing => 12;

  @override
  Widget build(BuildContext context) {
    List<StoryPagesBlock> blocks = StoryPagesBlock.buildBlocks(pages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: spacing,
      children: List.generate(
        blocks.length,
        (index) {
          // Each block can't have more than 3 pages,
          // we validate in assertion.
          //
          // I prefer explicit checking conditions.
          // Currently only support following layouts.
          final block = blocks[index];

          final firstPage = block.pages.elementAt(0);
          final secondPageOrNull = block.pages.elementAtOrNull(1);
          final thirdPageOrNull = block.pages.elementAtOrNull(2);

          if (firstPage.matched(1 / 2) &&
              secondPageOrNull?.matched(1 / 1) == true &&
              thirdPageOrNull?.matched(1 / 1) == true) {
            return buildGrid1LayoutBlock(
              context,
              firstPage,
              secondPageOrNull!,
              thirdPageOrNull!,
            );
          }

          if (firstPage.matched(1 / 1) &&
              secondPageOrNull?.matched(1 / 1) == true &&
              thirdPageOrNull?.matched(1 / 2) == true) {
            return buildGrid2LayoutBlock(
              context,
              firstPage,
              secondPageOrNull!,
              thirdPageOrNull!,
            );
          }

          if (firstPage.crossAxisCount == 1 && secondPageOrNull?.crossAxisCount == 1 && thirdPageOrNull == null) {
            return buildRowLayoutBlock(
              context,
              firstPage,
              secondPageOrNull!,
            );
          }

          return buildColumnLayoutBlock(block, context);
        },
      )..add(buildAddButton()),
    );
  }

  Widget buildColumnLayoutBlock(StoryPagesBlock block, BuildContext context) {
    return Column(
      spacing: spacing,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: block.pages.map((page) {
        return Container(
          constraints: pages.length == 1 ? const BoxConstraints(minHeight: 200) : null,
          child: buildPage(page, context),
        );
      }).toList(),
    );
  }

  IntrinsicHeight buildRowLayoutBlock(
    BuildContext context,
    StoryPageObject firstPage,
    StoryPageObject secondPage,
  ) {
    return IntrinsicHeight(
      child: Row(
        spacing: spacing,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(child: buildPage(firstPage, context)),
          Flexible(child: buildPage(secondPage, context)),
        ],
      ),
    );
  }

  Widget buildGrid1LayoutBlock(
    BuildContext context,
    StoryPageObject firstPage,
    StoryPageObject secondPage,
    StoryPageObject thirdPage,
  ) {
    return IntrinsicHeight(
      child: Row(
        spacing: spacing,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(child: buildPage(firstPage, context)),
          Flexible(
            child: Column(
              spacing: spacing,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(child: buildPage(secondPage, context)),
                buildPage(thirdPage, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGrid2LayoutBlock(
    BuildContext context,
    StoryPageObject firstPage,
    StoryPageObject secondPage,
    StoryPageObject thirdPage,
  ) {
    return IntrinsicHeight(
      child: Row(
        spacing: spacing,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              spacing: spacing,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(child: buildPage(firstPage, context)),
                buildPage(secondPage, context),
              ],
            ),
          ),
          Flexible(child: buildPage(thirdPage, context))
        ],
      ),
    );
  }

  Widget buildPage(StoryPageObject page, BuildContext context) {
    final pageIndex = pages.indexWhere((p) => page.id == p.id);

    bool canMoveUp = pageIndex > 0;
    bool canMoveDown = pageIndex < pages.length - 1;

    return _StoryPage(
      key: page.key,
      preferences: preferences,
      readOnly: readOnly,
      pageIndex: pageIndex,
      page: page,
      storyContent: storyContent,
      onSwap: actions?.onSwapPages,
      onDelete: actions == null ? null : () => actions?.onDelete(page),
      canMoveUp: canMoveUp,
      canMoveDown: canMoveDown,
      canDeletePage: actions?.canDeletePage == true,
      onChanged: actions?.onPageChanged,
      onFocusChange: actions?.onFocusChange != null ? (a, b) => actions!.onFocusChange(pageIndex, page, a, b) : null,
      onTitleVisibilityChanged:
          onTitleVisibilityChanged != null ? (info) => onTitleVisibilityChanged!(pageIndex, page, info) : null,
    );
  }

  // both should have same height, so switch between show / edit won't break scroll position.
  Widget buildAddButton() {
    return readOnly ? const SizedBox(height: 48) : _AddPageButton(onAddPage: () => actions!.onAddPage());
  }
}
