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
      backgroundColor: Colors.transparent,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: viewModel.story != null
          ? TagsEndDrawer(onUpdated: (tags) => viewModel.setTags(tags), initialTags: viewModel.story?.validTags ?? [])
          : null,
      onEndDrawerChanged: (isOpened) {
        if (isOpened) {
          context.read<RootProvider>().setTemporaryHidden(true);
        } else {
          context.read<RootProvider>().setTemporaryHidden(false);
        }
      },
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
          actions: null,
        ),
      ],
    );
  }

  Widget buildPageEditors(BuildContext context, List<StoryPageObject> pages) {
    return StoryPagesBuilder(
      viewInsets: MediaQuery.viewInsetsOf(context),
      headerBuilder: (page) => StoryHeader.fromShowStory(page: page, viewModel: viewModel, context: context),
      pageScrollController: viewModel.pagesManager.pageScrollController,
      padding: MediaQuery.paddingOf(context).copyWith(top: 0.0),
      pages: pages,
      preferences: viewModel.story?.preferences,
      storyContent: viewModel.draftContent!,
      onTitleVisibilityChanged: (pageIndex, page, info) =>
          viewModel.pagesManager.pagesMap.setTitleVisibleFraction(page.id, info.visibleFraction),
      pageController: viewModel.pagesManager.pageController,
      onPageChanged: (newRichPage) => viewModel.onPageChanged(newRichPage),
      onGoToEdit: () => viewModel.goToEditPage(context),
      actions: null,
    );
  }

  AppBar buildAppBar(BuildContext context, List<StoryPageObject> pages) {
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
          IconButton(
            color: Theme.of(context).appBarTheme.foregroundColor,
            tooltip: tr("button.edit"),
            onPressed: () => viewModel.goToEditPage(context),
            icon: const Icon(SpIcons.edit),
          ),
          const StoryEndDrawerButton(),
          StoryThemeButton(viewModel: viewModel),
        ],
        const SizedBox(width: 8.0),
      ],
    );
  }
}
