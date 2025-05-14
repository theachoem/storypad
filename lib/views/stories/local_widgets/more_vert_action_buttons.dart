part of 'story_pages_builder.dart';

class _MoreVertActionButtons extends StatelessWidget {
  const _MoreVertActionButtons({
    required this.pageIndex,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canDeletePage,
    required this.onSwap,
    required this.onDelete,
  });

  final int pageIndex;

  final bool canMoveUp;
  final bool canMoveDown;
  final bool canDeletePage;

  final void Function(int oldIndex, int newIndex) onSwap;
  final void Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return SpFloatingPopUpButton(
      estimatedFloatingWidth: 200,
      bottomToTop: false,
      dyGetter: (dy) => dy + 40,
      pathBuilder: PathBuilders.slideDown,
      floatingBuilder: (void Function() close) => buildFloatingCard(close, context),
      builder: (callback) {
        return SpTapEffect(
          scaleActive: 0.95,
          effects: [SpTapEffectType.scaleDown],
          onTap: callback,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorScheme.of(context).primary,
            ),
            child: Transform.scale(
              scale: 1.2,
              child: Icon(
                SpIcons.moreVert,
                size: 16,
                color: ColorScheme.of(context).onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFloatingCard(void Function() close, BuildContext context) {
    void swap({
      required int oldIndex,
      required int newIndex,
    }) {
      close();
      onSwap(oldIndex, newIndex);
    }

    void delete() {
      close();
      onDelete();
    }

    final actions = [
      IconButton(
        icon: const Icon(SpIcons.keyboardUp),
        onPressed: canMoveUp ? () => swap(oldIndex: pageIndex, newIndex: pageIndex - 1) : null,
      ),
      IconButton(
        icon: const Icon(SpIcons.keyboardDown),
        onPressed: canMoveDown ? () => swap(oldIndex: pageIndex, newIndex: pageIndex + 1) : null,
      ),
      IconButton(
        color: ColorScheme.of(context).error,
        icon: const Icon(SpIcons.delete),
        onPressed: canDeletePage ? () => delete() : null,
      ),
    ];

    int rowCount = (actions.length / 4).ceilToDouble().toInt();

    double itemSize = 48;
    double padding = 4.0;

    double contentsWidth = itemSize * min(4, actions.length);
    double width = contentsWidth + padding * 2 + 2;
    double height = itemSize * rowCount + padding * 2 + 2;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Wrap(
        spacing: 0.0,
        runSpacing: 0.0,
        children: actions.map((child) {
          return SizedBox(
            width: itemSize,
            height: itemSize,
            child: child,
          );
        }).toList(),
      ),
    );
  }
}
