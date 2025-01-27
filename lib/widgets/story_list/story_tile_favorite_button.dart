part of 'story_tile.dart';

class _StoryTileFavoriteButton extends StatelessWidget {
  const _StoryTileFavoriteButton({
    required this.story,
    required this.toggleStarred,
  });

  final StoryDbModel story;
  final Future<void> Function()? toggleStarred;

  @override
  Widget build(BuildContext context) {
    return CmSingleStateWidget(
      initialValue: story.starred == true,
      builder: (context, notifier) {
        final animationDuration = Durations.medium1;

        return IconButton(
          tooltip: 'Star',
          padding: const EdgeInsets.all(16.0),
          iconSize: 18.0,
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
              return SpAnimatedIcons(
                duration: animationDuration,
                showFirst: starred,
                firstChild: Icon(
                  Icons.favorite,
                  color: ColorScheme.of(context).error,
                  applyTextScaling: true,
                ),
                secondChild: Icon(
                  Icons.favorite_outline,
                  color: Theme.of(context).dividerColor,
                  applyTextScaling: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
