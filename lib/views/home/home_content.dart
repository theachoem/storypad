part of 'home_view.dart';

class _HomeContent extends StatelessWidget {
  const _HomeContent(this.viewModel);

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: viewModel.months.length,
      child: _HomeScaffold(
        viewModel: viewModel,
        endDrawer: _HomeEndDrawer(viewModel),
        appBar: HomeAppBar(viewModel: viewModel),
        body: buildBody(context),
        floatingActionButton: FloatingActionButton(
          onPressed: () => viewModel.goToNewPage(context),
          child: const Icon(Icons.edit),
        ),
      ),
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
          StoryDbModel story = viewModel.stories!.items[index];

          return StoryListenerBuilder(
            key: viewModel.scrollInfo.storyKeys[index],
            story: story,
            onChanged: (StoryDbModel updatedStory) => onChanged(updatedStory),
            // onDeleted only happen when reloaded story is null which not frequently happen. We just reload in this case.
            onDeleted: () => viewModel.load(debugSource: '$runtimeType#onDeleted ${story.id}'),
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
        },
      ),
    );
  }

  void onChanged(StoryDbModel updatedStory) {
    if (updatedStory.type != PathType.docs) {
      viewModel.stories = viewModel.stories?.removeElement(updatedStory);
      debugPrint('🚧 Removed ${updatedStory.id}:${updatedStory.type.name} by $runtimeType#onChanged');
    } else {
      viewModel.stories = viewModel.stories?.replaceElement(updatedStory);
      debugPrint('🚧 Updated ${updatedStory.id}:${updatedStory.type.name} contents by $runtimeType#onChanged');
    }

    viewModel.scrollInfo.setupStoryKeys(viewModel.stories?.items ?? []);
    viewModel.notifyListeners();
  }
}
