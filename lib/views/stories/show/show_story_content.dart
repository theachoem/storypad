part of 'show_story_view.dart';

class _ShowStoryContent extends StatelessWidget {
  const _ShowStoryContent(this.viewModel);

  final ShowStoryViewModel viewModel;

  List<StoryPageObject> constructPages() {
    if (viewModel.pagesManager.pagesMap.keys.isEmpty) return <StoryPageObject>[];
    return List.generate(viewModel.draftContent?.richPages?.length ?? 0, (index) {
      final page = viewModel.draftContent!.richPages![index];
      return viewModel.pagesManager.pagesMap[page.id];
    }).toList().whereType<StoryPageObject>().toList();
  }

  @override
  Widget build(BuildContext context) {
    List<StoryPageObject> pages = constructPages();

    return Scaffold(
      appBar: buildAppBar(context, pages),
      endDrawer: viewModel.story != null
          ? TagsEndDrawer(onUpdated: (tags) => viewModel.setTags(tags), initialTags: viewModel.story?.validTags ?? [])
          : null,
      body: buildBody(context, pages),
    );
  }

  Widget buildBody(BuildContext context, List<StoryPageObject> pages) {
    if (viewModel.story == null || viewModel.draftContent == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return IndexedStack(
      index: viewModel.pagesManager.managingPage ? 1 : 0,
      children: [
        buildPageEditors(context, pages),
        StoryPagesManager(
          viewModel: viewModel,
          mediaQueryPadding: MediaQuery.paddingOf(context),
        ),
      ],
    );
  }

  Widget buildPageEditors(BuildContext context, List<StoryPageObject> pages) {
    return StoryPagesBuilder(
      viewInsets: MediaQuery.viewInsetsOf(context),
      header: StoryHeader.fromShowStory(viewModel: viewModel, context: context),
      pageScrollController: viewModel.pagesManager.pageScrollController,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      pages: pages,
      preferences: viewModel.story?.preferences,
      storyContent: viewModel.draftContent!,
      onTitleVisibilityChanged: (pageIndex, page, info) =>
          viewModel.pagesManager.pagesMap.setTitleVisibleFraction(page.id, info.visibleFraction),
      pageController: viewModel.pagesManager.pageController,
      onPageChanged: (newRichPage) => viewModel.onPageChanged(newRichPage),
      actions: null,
    );
  }

  AppBar buildAppBar(BuildContext context, List<StoryPageObject> pages) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      titleSpacing: 0.0,
      leading: SpAnimatedIcons.fadeScale(
        showFirst: viewModel.pagesManager.managingPage,
        firstChild: CloseButton(onPressed: () => viewModel.pagesManager.toggleManagingPage()),
        secondChild: Hero(
          tag: 'back-button',
          child: BackButton(onPressed: () => Navigator.maybePop(context, viewModel.story)),
        ),
      ),
      actions: [
        if (!viewModel.pagesManager.managingPage) ...[
          IconButton(
            tooltip: tr("button.edit"),
            onPressed: () => viewModel.goToEditPage(context),
            icon: const Icon(SpIcons.edit),
          ),
          const StoryEndDrawerButton(),
          StoryThemeButton(viewModel: viewModel),
        ],
        if (viewModel.pagesManager.managingPage) ...[
          SpFadeIn.bound(
            delay: Durations.short1,
            child: StoryInfoButton(viewModel: viewModel),
          ),
        ],
        ManagePagesButton(viewModel: viewModel),
        const SizedBox(width: 8.0),
      ],
    );
  }
}
