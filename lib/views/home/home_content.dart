part of 'home_view.dart';

class _HomeContent extends StatelessWidget {
  const _HomeContent(this.viewModel);

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StoryListMultiEditWrapper(
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
        endDrawer: _HomeEndDrawer(viewModel),
        appBar: HomeAppBar(viewModel: viewModel),
        body: buildBody(context),
        bottomNavigationBar: buildBottomNavigationBar(context),
        floatingActionButton: buildNewStoryButton(context),
      ),
    );
  }

  Widget buildNewStoryButton(BuildContext context) {
    return StoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return Visibility(
          visible: !state.editing,
          child: FloatingActionButton(
            tooltip: tr("button.new_story"),
            onPressed: () => viewModel.goToNewPage(context),
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return StoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return SpMultiEditBottomNavBar(
          editing: state.editing,
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
    if (viewModel.stories == null) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (viewModel.stories!.items.isEmpty) {
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
        itemCount: viewModel.stories?.items.length ?? 0,
        itemBuilder: (context, index) {
          return buildStoryTile(
            index: index,
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
    return StoryListenerBuilder(
      key: viewModel.scrollInfo.storyKeys[index],
      story: story,
      onChanged: (StoryDbModel updatedStory) => viewModel.onAStoryReloaded(updatedStory),
      onDeleted: () => viewModel.reload(debugSource: '$runtimeType#onDeleted ${story.id}'),
      builder: (_) {
        return StoryTileListItem(
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
