import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_managable.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class StoryPagesManager extends StatelessWidget {
  const StoryPagesManager({
    super.key,
    required this.state,
  });

  final StoryPagesManagable state;

  @override
  Widget build(BuildContext context) {
    return AlignedGridView.extent(
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
        final controller = state.quillControllers[index];

        if (controller == null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildPageCard(
                context: context,
                child: Icon(Icons.add),
                onLongPressed: null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.addPage();
                },
              ),
            ],
          );
        }

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
                  onLongPressed: !state.canEditPages || state.pagesCount <= 1
                      ? null
                      : () async {
                          final result = await showOkCancelAlertDialog(
                            title: tr("dialog.are_you_sure_to_delete_this_page.title"),
                            context: context,
                            okLabel: tr("button.delete"),
                            isDestructiveAction: true,
                          );

                          if (result == OkCancelResult.ok) {
                            state.deletePage(index);
                          }
                        },
                  onTap: () {
                    HapticFeedback.selectionClick();
                    state.pageController.jumpToPage(index);
                    state.toggleManagingPage();
                  },
                ),
                if (state.currentPage == index) buildCheckIcon(context)
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              state.titleControllers[index]?.text.trim().isNotEmpty == true
                  ? state.titleControllers[index]!.text
                  : tr('input.title.hint'),
              textAlign: TextAlign.center,
              style: TextTheme.of(context).titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // SizedBox(height: 4.0),
            // Text(
            //   "4000 words",
            //   textAlign: TextAlign.center,
            //   style: TextTheme.of(context).bodyMedium,
            // ),
          ],
        );
      },
    );
  }

  Widget buildPageCard({
    required BuildContext context,
    required Widget child,
    required void Function() onTap,
    required void Function()? onLongPressed,
  }) {
    return AspectRatio(
      aspectRatio: 148 / 210,
      child: SpTapEffect(
        effects: [SpTapEffectType.scaleDown],
        onTap: onTap,
        onLongPressed: onLongPressed,
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

  Widget buildCheckIcon(BuildContext context) {
    return Positioned(
      top: -4,
      right: -4,
      child: Container(
        decoration: BoxDecoration(
          color: ColorScheme.of(context).secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          color: ColorScheme.of(context).onSecondary,
          size: 16.0,
        ),
      ),
    );
  }
}
