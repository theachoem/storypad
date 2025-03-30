part of 'story_pages_manager.dart';

class _StoryPagesBinTarget extends StatelessWidget {
  const _StoryPagesBinTarget({
    required this.state,
  });

  final StoryPagesManagable state;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: state.draggingNotifier,
      child: DragTarget<int>(
        onAcceptWithDetails: (details) async {
          final result = await showOkCancelAlertDialog(
            title: tr("dialog.are_you_sure_to_delete_this_page.title"),
            context: context,
            okLabel: tr("button.delete"),
            isDestructiveAction: true,
          );

          if (result == OkCancelResult.ok) state.deletePage(details.data);
        },
        builder: (context, candidateItems, rejectedItems) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: candidateItems.isNotEmpty ? ColorScheme.of(context).error : Colors.transparent,
              ),
              color:
                  candidateItems.isNotEmpty ? ColorScheme.of(context).errorContainer : ColorScheme.of(context).surface,
            ),
            padding: EdgeInsets.only(top: 16.0, bottom: MediaQuery.of(context).padding.bottom + 18.0),
            child: candidateItems.isNotEmpty
                ? Icon(MdiIcons.deleteEmpty, size: 32, color: ColorScheme.of(context).error)
                : Icon(MdiIcons.deleteOutline, size: 32),
          );
        },
      ),
      builder: (context, dragging, child) {
        return Visibility(
          visible: dragging && state.canDeletePage,
          child: SpFadeIn.fromBottom(
            child: child!,
          ),
        );
      },
    );
  }
}
