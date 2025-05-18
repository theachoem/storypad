part of 'story_pages_manager.dart';

class _StoryPagesBinTarget extends StatelessWidget {
  final StoryPagesManagerInfo pagesManager;
  final void Function(int pageIndex) onDeletePage;

  const _StoryPagesBinTarget({
    required this.pagesManager,
    required this.onDeletePage,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pagesManager.draggingNotifier,
      child: DragTarget<int>(
        onAcceptWithDetails: (details) => onDeletePage(details.data),
        builder: (context, candidateItems, rejectedItems) {
          return Container(
            decoration: BoxDecoration(
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
          visible: dragging && pagesManager.canDeletePage,
          child: SpFadeIn.fromBottom(
            child: child!,
          ),
        );
      },
    );
  }
}
