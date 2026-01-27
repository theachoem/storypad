part of 'home_view.dart';

class _HomeContent extends StatelessWidget {
  const _HomeContent(this.viewModel);

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpStoryListMultiEditWrapper(
      builder: (BuildContext context) {
        return buildScaffold(context);
      },
    );
  }

  Widget buildScaffold(BuildContext context) {
    return DefaultTabController(
      length: viewModel.months.length,
      child: _HomeScaffold(
        viewModel: viewModel,
        endDrawer: buildEndDrawer(context),
        appBar: _HomeAppBar(viewModel: viewModel),
        body: buildBody(context),
        bottomNavigationBar: buildBottomNavigationBar(context),
        floatingActionButton: buildFloatingButtons(context),
      ),
    );
  }

  Widget buildEndDrawer(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<RootProvider>().sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        bool bigScreen = sideBarInfo?.bigScreen ?? false;

        Widget drawer = Drawer(
          width: bigScreen ? 400 : null,
          child: bigScreen ? const SpNestedNavigation(initialScreen: HomeEndDrawer()) : const HomeEndDrawer(),
        );

        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(
                // On desktop platforms, left/right safe areas are typically handled in the root view to center content.
                // For the drawer, we intentionally remove left/right padding to allow it to use the full width.
                left: 0,
                right: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
            ),
            child: drawer,
          );
        } else {
          return drawer;
        }
      },
    );
  }

  Widget buildFloatingButtons(BuildContext context) {
    return SpStoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return Visibility(
          visible: !state.editing,
          child: _HomeFloatingButtons(viewModel: viewModel),
        );
      },
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return SpStoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        if (!state.editing) return const SpFloatingRelaxSoundsTile(fromHome: true);

        List<StoryDbModel> stories = [
          ...viewModel.stories?.items.where((story) {
                return state.selectedStories.contains(story.id);
              }) ??
              [],
          ...viewModel.pinnedStories?.items.where((story) {
                return state.selectedStories.contains(story.id);
              }) ??
              [],
        ];

        bool allPinned = stories.every((story) => story.pinned == true);

        return SpMultiEditBottomNavBar(
          editing: true,
          onCancel: () => state.turnOffEditing(),
          buttons: [
            _PinStoryIconButton(state: state, allPinned: allPinned, stories: stories, viewModel: viewModel),
            IconButton.outlined(
              tooltip: "${tr("button.archive")} (${state.selectedStories.length})",
              icon: const Icon(SpIcons.archive),
              onPressed: stories.isEmpty ? null : () => state.archiveAll(context),
            ),
            IconButton.outlined(
              tooltip: "${tr("button.move_to_bin")} (${state.selectedStories.length})",
              icon: const Icon(SpIcons.delete),
              onPressed: stories.isEmpty ? null : () => state.moveToBinAll(context),
            ),
          ],
        );
      },
    );
  }

  Widget buildBody(BuildContext listContext) {
    int itemsCount = viewModel.stories?.items.length ?? 0;

    bool hasPinnedOrThrowback = viewModel.hasPinned || viewModel.hasThrowback;
    if (hasPinnedOrThrowback) itemsCount += 1;

    if (viewModel.stories == null) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (itemsCount == 0) {
      return SliverFillRemaining(
        child: _HomeEmpty(viewModel: viewModel),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        top: 0.0,
        left: MediaQuery.of(listContext).padding.left,
        right: MediaQuery.of(listContext).padding.right,
        bottom: kToolbarHeight + 200 + MediaQuery.of(listContext).padding.bottom,
      ),
      sliver: SliverList.builder(
        itemCount: itemsCount,
        itemBuilder: (context, itemIndex) {
          if (itemIndex == 0 && hasPinnedOrThrowback) {
            return Column(
              children: [
                if (viewModel.hasThrowback)
                  SpThrowbackTile(
                    listHasStories: viewModel.stories?.items.isNotEmpty == true,
                    throwbackDates: viewModel.throwbackDates,
                  ),
                for (int pinnedIndex = 0; pinnedIndex < (viewModel.pinnedStories?.items.length ?? 0); pinnedIndex++)
                  buildStoryTile(
                    index: pinnedIndex,
                    context: context,
                    listContext: listContext,
                    stories: viewModel.pinnedStories!,
                  ),
              ],
            );
          }

          int storyIndex = itemIndex;
          if (hasPinnedOrThrowback) storyIndex = itemIndex - 1;

          return buildStoryTile(
            index: storyIndex,
            context: context,
            listContext: listContext,
            stories: viewModel.stories!,
          );
        },
      ),
    );
  }

  Widget buildStoryTile({
    required int index,
    required BuildContext context,
    required BuildContext listContext,
    required CollectionDbModel<StoryDbModel> stories,
  }) {
    StoryDbModel story = stories.items[index];

    return SpStoryListenerBuilder(
      key: viewModel.scrollInfo.getKeyForStoryIndex(story.pinned, index),
      story: story,
      onChanged: (StoryDbModel updatedStory) => viewModel.onAStoryReloaded(updatedStory),
      onDeleted: () => viewModel.onAStoryDeleted(story),
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: viewModel.scrollInfo.scrollingToStoryIdNotifier,
                builder: (context, storyId, child) {
                  return AnimatedContainer(
                    duration: Durations.long4,
                    color: storyId == story.id ? ColorScheme.of(context).readOnly.surface5 : Colors.transparent,
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            SpStoryTileListItem(
              listHasPinned: viewModel.hasPinned,
              showYear: false,
              index: index,
              stories: stories,
              onTap: () => viewModel.goToViewPage(context, story),
              listContext: listContext,
              listHasThrowback: viewModel.hasThrowback,
            ),
          ],
        );
      },
    );
  }
}
