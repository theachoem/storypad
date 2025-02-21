part of 'story_tile.dart';

class _StoryTileFavoriteButton extends StatelessWidget {
  const _StoryTileFavoriteButton({
    required this.story,
    required this.toggleStarred,
    required this.updateStarIcon,
    required this.multiEditState,
  });

  final StoryDbModel story;
  final Future<void> Function()? toggleStarred;
  final Future<void> Function(String starIcon)? updateStarIcon;
  final StoryListMultiEditWrapperState? multiEditState;

  @override
  Widget build(BuildContext context) {
    if (multiEditState == null) return buildFavoriteButton();

    return SpAnimatedIcons(
      showFirst: !multiEditState!.editing,
      firstChild: buildFavoriteButton(),
      secondChild: Checkbox.adaptive(
        value: multiEditState!.selectedStories.contains(story.id),
        onChanged: (_) => multiEditState!.toggleSelection(story),
      ),
    );
  }

  Widget buildFavoriteButton() {
    return CmSingleStateWidget(
      initialValue: story.starred == true,
      builder: (context, notifier) {
        final animationDuration = Durations.medium1;

        int rowCount = (StoryIconObject.icons.length / 4).ceilToDouble().toInt();

        double itemSize = 48;
        double padding = 4.0;

        double contentsWidth = itemSize * min(4, StoryIconObject.icons.length);
        double width = contentsWidth + padding * 2 + 2;
        double height = itemSize * rowCount + padding * 2 + 2;

        return SpFloatingPopUpButton(
          estimatedFloatingWidth: width,
          bottomToTop: false,
          dyGetter: (dy) => dy + 48,
          pathBuilder: PathBuilders.slideDown,
          floatingBuilder: (callback) => buildStarIconFloating(
            width: width,
            height: height,
            padding: padding,
            context: context,
            notifier: notifier,
            itemSize: itemSize,
          ),
          builder: (callback) {
            return buildStarButton(
              callback: callback,
              notifier: notifier,
              animationDuration: animationDuration,
            );
          },
        );
      },
    );
  }

  Widget buildStarIconFloating({
    required double width,
    required double height,
    required double padding,
    required BuildContext context,
    required CmValueNotifier<bool> notifier,
    required double itemSize,
  }) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: ColorScheme.of(context).onSurface.withValues(alpha: 0.1), width: 1),
      ),
      child: Wrap(
        spacing: 0.0,
        runSpacing: 0.0,
        children: StoryIconObject.icons.entries.map((entry) {
          Widget child;

          bool defaultIcon =
              story.starIcon == null && entry.value.filledIcon == StoryIconObject.fallbackIcon.filledIcon;

          if (entry.key == story.starIcon || defaultIcon) {
            child = IconButton.filledTonal(
              icon: Icon(entry.value.outlineIcon),
              onPressed: () => updateStarIcon?.call(entry.key),
            );
          } else {
            child = IconButton(
              icon: Icon(entry.value.outlineIcon),
              onPressed: () => updateStarIcon?.call(entry.key),
            );
          }

          return SizedBox(
            width: itemSize,
            height: itemSize,
            child: Center(child: child),
          );
        }).toList(),
      ),
    );
  }

  Widget buildStarButton({
    required VoidCallback callback,
    required CmValueNotifier<bool> notifier,
    required Duration animationDuration,
  }) {
    return IconButton(
      tooltip: tr("button.star"),
      padding: const EdgeInsets.all(16.0),
      iconSize: 18.0,
      onLongPress: callback,
      onPressed: toggleStarred == null
          ? null
          : () async {
              notifier.value = !notifier.value;
              await Future.delayed(animationDuration);
              await toggleStarred?.call();
            },
      icon: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, starred, child) {
          return Transform.scale(
            scale: StoryIconObject.icons[story.starIcon]?.scale ?? StoryIconObject.fallbackIcon.scale,
            child: SpAnimatedIcons(
              duration: animationDuration,
              showFirst: starred,
              firstChild: Icon(
                StoryIconObject.icons[story.starIcon]?.filledIcon ?? StoryIconObject.fallbackIcon.filledIcon,
                color: ColorScheme.of(context).error,
                applyTextScaling: true,
              ),
              secondChild: Icon(
                StoryIconObject.icons[story.starIcon]?.outlineIcon ?? StoryIconObject.fallbackIcon.outlineIcon,
                color: Theme.of(context).dividerColor,
                applyTextScaling: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
