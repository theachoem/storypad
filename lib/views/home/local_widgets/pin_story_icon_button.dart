part of '../home_view.dart';

class _PinStoryIconButton extends StatelessWidget {
  const _PinStoryIconButton({
    required this.state,
    required this.allPinned,
    required this.stories,
    required this.viewModel,
  });

  final bool allPinned;
  final SpStoryListMultiEditWrapperState state;
  final List<StoryDbModel> stories;
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton.outlined(
          tooltip: allPinned
              ? "${tr("button.unpin_story")} (${state.selectedStories.length})"
              : "${tr("button.pin_story")} (${state.selectedStories.length})",
          icon: allPinned ? Icon(SpIcons.pinSlash) : Icon(SpIcons.pin),
          color: allPinned ? null : ColorScheme.of(context).primary,
          onPressed: stories.isEmpty ? null : () => viewModel.togglePinForStories(state, context),
        ),
      ],
    );
  }
}
