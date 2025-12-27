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
    return GestureDetector(
      onTap: context.read<InAppPurchaseProvider>().pinnedNotes
          ? null
          : () => const RewardsRoute(initialFocusedRewardFeature: .pinned_notes).push(context),
      child: Stack(
        children: [
          IconButton.outlined(
            tooltip: allPinned
                ? "${tr("button.unpin_story")} (${state.selectedStories.length})"
                : "${tr("button.pin_story")} (${state.selectedStories.length})",
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                allPinned ? Icon(SpIcons.pinSlash) : Icon(SpIcons.pin),
                if (!context.read<InAppPurchaseProvider>().pinnedNotes)
                  const Positioned(
                    bottom: -4,
                    right: -12,
                    child: Icon(SpIcons.lock, size: 16.0),
                  ),
              ],
            ),
            color: allPinned ? null : ColorScheme.of(context).primary,
            onPressed: !context.read<InAppPurchaseProvider>().pinnedNotes
                ? null
                : stories.isEmpty
                ? null
                : () => viewModel.togglePinForStories(state, context),
          ),
        ],
      ),
    );
  }
}
