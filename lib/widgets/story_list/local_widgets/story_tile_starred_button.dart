part of '../sp_story_tile.dart';

class _StoryTileStarredButton extends StatelessWidget {
  const _StoryTileStarredButton({
    required this.story,
    required this.viewOnly,
    required this.listContext,
    required this.multiEditState,
  });

  final StoryDbModel story;
  final bool viewOnly;
  final BuildContext listContext;
  final SpStoryListMultiEditWrapperState? multiEditState;

  @override
  Widget build(BuildContext context) {
    double x = -16.0 * 2 + 48.0;
    double y = 16.0 * 2 - 48.0;

    if (AppTheme.rtl(context)) {
      x = -16.0 * 2 + 16.0;
      y = 16.0 * 2 - 48.0;
    }

    return Positioned(
      left: AppTheme.getDirectionValue(context, 0.0, null),
      right: AppTheme.getDirectionValue(context, null, 0.0),
      child: Container(
        transform: Matrix4.identity()..spTranslate(x, y),
        child: _StoryTileFavoriteButton(
          story: story,
          toggleStarred: viewOnly ? null : _StoryTileActions(story: story, listContext: listContext).toggleStarred,
          multiEditState: multiEditState,
          updateStarIcon: viewOnly ? null : _StoryTileActions(story: story, listContext: listContext).updateStarIcon,
        ),
      ),
    );
  }
}
