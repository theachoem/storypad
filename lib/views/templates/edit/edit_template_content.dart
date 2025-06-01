part of 'edit_template_view.dart';

class _EditTemplateContent extends StatelessWidget {
  const _EditTemplateContent(this.viewModel);

  final EditTemplateViewModel viewModel;

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
      endDrawer: TagsEndDrawer(
        onUpdated: (tags) => viewModel.setTags(tags),
        initialTags: viewModel.template?.tags ?? [],
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: CupertinoSheetRoute.hasParentSheet(context) ? null : const CloseButton(),
        actions: [
          _DoneButton(viewModel: viewModel),
          const SizedBox(width: 8.0),
          const StoryEndDrawerButton(),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
      ),
      body: buildBody(context, pages),
    );
  }

  Widget buildBody(BuildContext context, List<StoryPageObject> pages) {
    if (viewModel.draftContent == null || pages.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return StoryPagesBuilder(
      preferences: StoryPreferencesDbModel.create(),
      pages: pages,
      storyContent: viewModel.draftContent!,
      header: null,
      padding: MediaQuery.paddingOf(context),
      pageScrollController: null,
      viewInsets: MediaQuery.viewInsetsOf(context),
      onPageChanged: (newRichPage) => viewModel.onPageChanged(newRichPage),
      actions: StoryPageBuilderAction(
        onAddPage: () => viewModel.addNewPage(),
        onSwapPages: (oldIndex, newIndex) => viewModel.swapPages(oldIndex: oldIndex, newIndex: newIndex),
        onDelete: (page) => viewModel.deleteAPage(context, page.page),
        onFocusChange: (pageIndex, page, titleFocused, bodyFocused) {},
        canDeletePage: viewModel.pagesManager.canDeletePage,
      ),
    );
  }
}
