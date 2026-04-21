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
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context),
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
          actions: getPageActions(context),
        ),
      ],
    );
  }

  Widget buildPageEditors(BuildContext context, List<StoryPageObject> pages) {
    return StoryPagesBuilder(
      viewInsets: MediaQuery.viewInsetsOf(context),
      headerBuilder: (page) => StoryHeader.fromEditStory(page: page, viewModel: viewModel, context: context),
      pageScrollController: viewModel.pagesManager.pageScrollController,
      padding: MediaQuery.paddingOf(context).copyWith(top: 0.0),
      pages: pages,
      preferences: viewModel.story!.preferences,
      storyContent: viewModel.draftContent!,
      pageController: viewModel.pagesManager.pageController,
      onPageChanged: (newRichPage) => viewModel.onPageChanged(newRichPage),
      actions: getPageActions(context),
    );
  }

  StoryPageBuilderAction getPageActions(BuildContext context) {
    return StoryPageBuilderAction(
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
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      titleSpacing: 0.0,
      // On large screens, its side padding prevents the divider
      // from spanning the full width of the screen. To avoid this visual
      // inconsistency, we hide the divider when the window is large.
      bottom: WindowedDetectorService.isBigWindow(context)
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: ValueListenableBuilder(
                valueListenable: viewModel.pagesManager.pageScrollOffsetNotifier,
                builder: (BuildContext context, double offset, Widget? child) {
                  return Opacity(
                    opacity: offset.clamp(0.0, 8.0) / 8.0,
                    child: const Divider(height: 1),
                  );
                },
              ),
            ),
      leading: SpAnimatedIcons.fadeScale(
        showFirst: viewModel.pagesManager.managingPage,
        firstChild: CloseButton(onPressed: () => viewModel.pagesManager.toggleManagingPage()),
        secondChild: Hero(
          tag: 'back-button',
          child: BackButton(
            color: Theme.of(context).appBarTheme.foregroundColor,
            onPressed: () => Navigator.maybePop(context, viewModel.story),
          ),
        ),
      ),
      actions: [
        if (!viewModel.pagesManager.managingPage) ...[
          _DoneButton(viewModel: viewModel),
          const SizedBox(width: 8.0),
          StoryThemeButton(viewModel: viewModel),
        ],
        const SizedBox(width: 8.0),
      ],
    );
  }
}
