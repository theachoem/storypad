import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_reorderable_item.dart';

part 'story_pages_bin_target.dart';
part 'checked_icon.dart';

class StoryPagesManager extends StatelessWidget {
  const StoryPagesManager({
    super.key,
    required this.viewModel,
    required this.mediaQueryPadding,
  });

  final BaseStoryViewModel viewModel;
  final EdgeInsets mediaQueryPadding;

  @override
  Widget build(BuildContext context) {
    final richPages = viewModel.draftContent?.richPages ?? <StoryPageDbModel>[];

    return Stack(
      children: [
        AlignedGridView.extent(
          padding: const EdgeInsetsDirectional.all(16.0).add(EdgeInsets.only(
            left: mediaQueryPadding.left,
            right: mediaQueryPadding.right,
            bottom: mediaQueryPadding.bottom,
          )),
          maxCrossAxisExtent: 150,
          itemCount: richPages.length + 1,
          mainAxisSpacing: 24.0,
          crossAxisSpacing: 8.0,
          itemBuilder: (context, index) {
            final richPage = richPages.elementAtOrNull(index);
            if (richPage == null) return buildNewPage(context);

            final page = viewModel.pagesManager.pagesMap[richPage.id];
            if (page == null) return const SizedBox.shrink();

            Widget child = buildPage(context, page, index);
            return SpReorderableItem(
              index: index,
              onAccepted: (int oldIndex) => viewModel.reorderPages(oldIndex: oldIndex, newIndex: index),
              onDragStarted: () => viewModel.pagesManager.draggingNotifier.value = true,
              onDragCompleted: () => viewModel.pagesManager.draggingNotifier.value = false,
              child: child,
            );
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _StoryPagesBinTarget(
            mediaQueryPadding: mediaQueryPadding,
            pagesManager: viewModel.pagesManager,
            onDeletePage: (pageIndex) => viewModel.deleteAPage(context, richPages[pageIndex]),
          ),
        )
      ],
    );
  }

  Widget buildNewPage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildPageCard(
          context: context,
          child: const Icon(SpIcons.add),
          onTap: () {
            HapticFeedback.selectionClick();
            viewModel.addNewPage();
          },
        ),
      ],
    );
  }

  Widget buildPage(BuildContext context, StoryPageObject page, int pageIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            buildPageCard(
              context: context,
              child: Text(page.bodyController.document.toPlainText()),
              onTap: () {
                HapticFeedback.selectionClick();
                viewModel.pagesManager.toggleManagingPage();

                if (viewModel.pagesManager.pageScrollController.hasClients) {
                  viewModel.pagesManager.scrollToPage(page.id);
                } else if (viewModel.pagesManager.pageController.hasClients) {
                  viewModel.pagesManager.pageController.jumpToPage(pageIndex);
                }
              },
            ),
            ValueListenableBuilder(
              valueListenable: viewModel.pagesManager.currentPageIndexNotifier,
              child: const _CheckedIcon(),
              builder: (context, currentPageIndex, child) {
                return Visibility(
                  visible: pageIndex == currentPageIndex,
                  child: child!,
                );
              },
            )
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          page.titleController.text.trim().isNotEmpty == true
              ? page.titleController.text.trim()
              : tr('input.title.hint'),
          textAlign: TextAlign.center,
          style: TextTheme.of(context).titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Text(
        //   "4000 words",
        //   textAlign: TextAlign.center,
        //   style: TextTheme.of(context)
        //       .bodyMedium
        //       ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        // ),
      ],
    );
  }

  Widget buildPageCard({
    required BuildContext context,
    required Widget child,
    required void Function() onTap,
  }) {
    return AspectRatio(
      aspectRatio: 148 / 210,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: ColorScheme.of(context).surface,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
