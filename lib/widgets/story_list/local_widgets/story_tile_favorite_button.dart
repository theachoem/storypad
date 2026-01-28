part of '../sp_story_tile.dart';

class _StoryTileFavoriteButton extends StatelessWidget {
  const _StoryTileFavoriteButton({
    required this.story,
    required this.toggleStarred,
    required this.multiEditState,
  });

  final StoryDbModel story;
  final Future<void> Function()? toggleStarred;
  final SpStoryListMultiEditWrapperState? multiEditState;

  @override
  Widget build(BuildContext context) {
    if (multiEditState == null) return buildFavoriteButton();

    return SpAnimatedIcons(
      showFirst: !multiEditState!.editing,
      firstChild: buildFavoriteButton(),
      secondChild: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(
          minWidth: 50.0,
          minHeight: 50.0,
        ),
        child: Checkbox.adaptive(
          value: multiEditState!.selectedStories.contains(story.id),
          onChanged: (_) => multiEditState!.toggleSelection(story),
        ),
      ),
    );
  }

  Widget buildFavoriteButton() {
    return SpSingleStateWidget(
      initialValue: story.starred == true,
      builder: (context, notifier) {
        return IconButton(
          tooltip: tr("button.star"),
          padding: const EdgeInsets.all(16.0),
          iconSize: 18.0,
          onPressed: toggleStarred == null
              ? null
              : () async {
                  notifier.value = !notifier.value;
                  await toggleStarred?.call();
                },
          icon: ValueListenableBuilder(
            valueListenable: notifier,
            builder: (context, starred, child) {
              return SpAnimatedIcons(
                duration: Durations.medium1,
                showFirst: starred,
                firstChild: Icon(
                  SpIcons.bookmarkFilled,
                  color: ColorScheme.of(context).error,
                  applyTextScaling: true,
                ),
                secondChild: Icon(
                  SpIcons.bookmark,
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
