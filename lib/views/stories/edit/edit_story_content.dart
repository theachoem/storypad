part of 'edit_story_view.dart';

class _EditStoryContent extends StatelessWidget {
  const _EditStoryContent(this.viewModel);

  final EditStoryViewModel viewModel;

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
      appBar: buildAppBar(context),
      endDrawer: viewModel.story != null
          ? TagsEndDrawer(
              onUpdated: (tags) => viewModel.setTags(tags),
              initialTags: viewModel.story?.validTags ?? [],
            )
          : null,
      body: buildBody(context, pages),
      bottomNavigationBar: viewModel.story == null
          ? null
          : SpPagesToolbar(
              managingPage: viewModel.pagesManager.managingPage,
              pages: pages,
              backgroundColor: ColorScheme.of(context).readOnly.surface1,
              preferences: viewModel.story!.preferences,
              onThemeChanged: (preferences) => viewModel.changePreferences(preferences),
            ),
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
      headerBuilder: (page) => StoryHeader.fromEditStory(page: page, viewModel: viewModel, context: context),
      pageScrollController: viewModel.pagesManager.pageScrollController,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: 16.0,
      ),
      pages: pages,
      preferences: viewModel.story!.preferences,
      storyContent: viewModel.draftContent!,
      pageController: viewModel.pagesManager.pageController,
      onPageChanged: (newRichPage) => viewModel.onPageChanged(newRichPage),
      actions: StoryPageBuilderAction(
        onAddPage: () => viewModel.addNewPage(),
        onSwapPages: (oldIndex, newIndex) => viewModel.reorderPages(oldIndex: oldIndex, newIndex: newIndex),
        onDelete: (page) => viewModel.deleteAPage(context, page.page),
        canDeletePage: viewModel.pagesManager.canDeletePage,
        onFocusChange: (pageIndex, page, titleFocused, bodyFocused) {
          if (titleFocused) {
            if (viewModel.pagesManager.pageScrollController.hasClients) {
              viewModel.pagesManager.scrollToPage(page.id);
            }
          }
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading: SpAnimatedIcons.fadeScale(
        showFirst: viewModel.pagesManager.managingPage,
        firstChild: CloseButton(onPressed: () => viewModel.pagesManager.toggleManagingPage()),
        secondChild: Hero(
          tag: 'back-button',
          child: BackButton(onPressed: () => Navigator.maybePop(context, viewModel.story)),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      titleSpacing: 0.0,
      actions: [
        if (!viewModel.pagesManager.managingPage) ...[
          _DoneButton(viewModel: viewModel),
          const SizedBox(width: 8.0),
          const StoryEndDrawerButton(),
          StoryThemeButton(viewModel: viewModel),
        ],
        const SizedBox(width: 8.0),
      ],
    );
  }
}
