import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/widgets/rich_editor/sp_editor.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/views/stories/local_widgets/more_vert_action_buttons.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_focus_node_builder.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_page_view_datas.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 'story_page.dart';
part 'add_page_button.dart';
part 'story_page_builder_action.dart';

part 'layouts/pages_layout.dart';
part 'layouts/list_layout.dart';
part 'layouts/grid_layout.dart';

class StoryPagesBuilder extends StatelessWidget {
  const StoryPagesBuilder({
    super.key,
    required this.preferences,
    required this.pages,
    required this.storyContent,
    required this.headerBuilder,
    required this.padding,
    required this.pageScrollController,
    required this.pageController,
    this.bottomSpacing = 0.0,
    this.onTitleVisibilityChanged,
    this.onPageChanged,
    this.onGoToEdit,
    this.actions,
  });

  final ScrollController? pageScrollController;

  /// Around the pages, but not below them: there's the bottom safe area as the keyboard leaves it, plus
  /// [bottomSpacing] (see [_BottomSafeArea]). Pass the view padding (`MediaQuery.viewPaddingOf`), which the keyboard
  /// doesn't change, so its animation doesn't rebuild the pages.
  final EdgeInsets padding;
  final double bottomSpacing;

  /// [StoryHeader]
  final Widget Function(StoryPageObject page)? headerBuilder;
  final StoryPreferencesDbModel? preferences;
  final PageController pageController;
  final StoryContentDbModel storyContent;
  final List<StoryPageObject> pages;

  // move out of action because even in read only mode, we should still listen to change.
  final VoidCallback? onPageChanged;
  final void Function()? onGoToEdit;
  final StoryPageBuilderAction? actions;
  final void Function(int pageIndex, StoryPageObject page, VisibilityInfo info)? onTitleVisibilityChanged;

  bool get readOnly => actions == null;

  double get spacing => 12;

  @override
  Widget build(BuildContext context) {
    switch (preferences?.layoutType) {
      case PageLayoutType.list:
        return _ListLayout(builder: this);
      case PageLayoutType.grid:
        return _GridLayout(builder: this);
      case PageLayoutType.pages:
      case null:
        return _PagesLayout(builder: this);
    }
  }

  Widget buildPage(
    StoryPageObject page,
    BuildContext context, {
    bool smallPage = true,
  }) {
    final pageIndex = pages.indexWhere((p) => page.id == p.id);

    return _StoryPage(
      key: page.key,
      preferences: preferences,
      smallPage: smallPage,
      readOnly: readOnly,
      pageIndex: pageIndex,
      page: page,
      storyContent: storyContent,
      onSwap: actions?.onSwapPages,
      onDelete: actions == null ? null : () => actions?.onDelete(page),
      canMoveUp: actions == null ? false : actions!.canMoveUp(pageIndex),
      canMoveDown: actions == null ? false : actions!.canMoveDown(pageIndex, pages.length),
      canDeletePage: actions?.canDeletePage == true,
      onChanged: onPageChanged,
      onTitleVisibilityChanged: onTitleVisibilityChanged != null
          ? (info) => onTitleVisibilityChanged!(pageIndex, page, info)
          : null,
      onGoToEdit: onGoToEdit,
    );
  }

  Widget _buildBottomSafeArea() => _BottomSafeArea(extra: bottomSpacing);

  // both should have same height, so switch between show / edit won't break scroll position.
  Widget _buildAddButton() {
    return readOnly ? const SizedBox(height: 48) : _AddPageButton(onAddPage: () => actions!.onAddPage());
  }
}

/// The bottom safe area as the keyboard leaves it (the home indicator's inset shrinks to 0 under the keyboard), plus
/// [extra]. Read here alone, so the keyboard's animation rebuilds this spacer instead of every page's editor.
class _BottomSafeArea extends StatelessWidget {
  const _BottomSafeArea({required this.extra});

  final double extra;

  @override
  Widget build(BuildContext context) => SizedBox(height: MediaQuery.paddingOf(context).bottom + extra);
}
