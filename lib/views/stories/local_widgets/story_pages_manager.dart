import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_managable.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_reorderable_item.dart';

part 'story_pages_bin_target.dart';
part 'checked_icon.dart';

class StoryPagesManager extends StatelessWidget {
  const StoryPagesManager({
    super.key,
    required this.state,
  });

  final StoryPagesManagable state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AlignedGridView.extent(
          padding: EdgeInsetsDirectional.all(16.0).add(EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
            bottom: MediaQuery.of(context).padding.bottom,
          )),
          maxCrossAxisExtent: 150,
          itemCount: state.canEditPages ? state.pagesCount + 1 : state.pagesCount,
          mainAxisSpacing: 24.0,
          crossAxisSpacing: 8.0,
          itemBuilder: (context, index) {
            final controller = state.quillControllers.elementAtOrNull(index);
            if (controller == null) return buildNewPage(context);

            Widget page = buildPage(context, controller, index);
            if (state.canEditPages) {
              return SpReorderableItem(
                index: index,
                onAccepted: (int oldIndex) => state.reorderPages(oldIndex: oldIndex, newIndex: index),
                onDragStarted: () => state.draggingNotifier.value = true,
                onDragCompleted: () => state.draggingNotifier.value = false,
                child: page,
              );
            }

            return page;
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _StoryPagesBinTarget(state: state),
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
          child: Icon(SpIcons.of(context).add),
          onTap: () {
            HapticFeedback.selectionClick();
            state.addPage();
          },
        ),
      ],
    );
  }

  Widget buildPage(BuildContext context, QuillController controller, int index) {
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
              child: Text(controller.document.toPlainText()),
              onTap: () {
                HapticFeedback.selectionClick();
                state.pageController.jumpToPage(index);
                state.toggleManagingPage();
              },
            ),
            if (state.currentPage == index) _CheckedIcon()
          ],
        ),
        SizedBox(height: 8.0),
        Text(
          state.titleControllers[index].text.trim().isNotEmpty == true
              ? state.titleControllers[index].text
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
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
