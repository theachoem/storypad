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
        endDrawer: LayoutBuilder(
          builder: (context, constraints) {
            return Drawer(
              // we want to make it look like a side panel on larger screens.
              width: constraints.maxWidth >= 450 ? 400 : null,
              child: const SpNestedNavigation(initialScreen: HomeEndDrawer()),
            );
          },
        ),
        appBar: _HomeAppBar(viewModel: viewModel),
        body: buildBody(context),
        bottomNavigationBar: buildBottomNavigationBar(context),
        floatingActionButton: buildFloatingButtons(context),
      ),
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
        return SpMultiEditBottomNavBar(
          editing: true,
          onCancel: () => state.turnOffEditing(),
          buttons: [
            OutlinedButton(
              child: Text("${tr("button.archive")} (${state.selectedStories.length})"),
              onPressed: () => state.archiveAll(context),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ColorScheme.of(context).error),
              child: Text("${tr("button.move_to_bin")} (${state.selectedStories.length})"),
              onPressed: () => state.moveToBinAll(context),
            ),
          ],
        );
      },
    );
  }

  Widget buildBody(BuildContext listContext) {
    int itemsCount = viewModel.stories?.items.length ?? 0;
    if (viewModel.hasThrowback) itemsCount += 1;

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
        top: 16.0,
        left: MediaQuery.of(listContext).padding.left,
        right: MediaQuery.of(listContext).padding.right,
        bottom: kToolbarHeight + 200 + MediaQuery.of(listContext).padding.bottom,
      ),
      sliver: SliverList.builder(
        itemCount: itemsCount,
        itemBuilder: (context, itemIndex) {
          if (viewModel.hasThrowback && itemIndex == 0) {
            return _ThrowbackTile(
              throwbackDates: viewModel.throwbackDates,
            );
          }

          int storyIndex = itemIndex;
          if (viewModel.hasThrowback) storyIndex = itemIndex - 1;

          return buildStoryTile(
            index: storyIndex,
            context: context,
            listContext: listContext,
          );
        },
      ),
    );
  }

  Widget buildStoryTile({
    required int index,
    required BuildContext context,
    required BuildContext listContext,
  }) {
    StoryDbModel story = viewModel.stories!.items[index];
    return SpStoryListenerBuilder(
      key: viewModel.scrollInfo.storyKeys[index],
      story: story,
      onChanged: (StoryDbModel updatedStory) => viewModel.onAStoryReloaded(updatedStory),
      onDeleted: () => viewModel.reload(debugSource: '$runtimeType#onDeleted ${story.id}'),
      builder: (_) {
        return SpStoryTileListItem(
          showYear: false,
          index: index,
          stories: viewModel.stories!,
          onTap: () => viewModel.goToViewPage(context, story),
          listContext: listContext,
        );
      },
    );
  }
}
