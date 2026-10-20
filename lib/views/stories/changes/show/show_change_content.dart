part of 'show_change_view.dart';

class _ShowChangeContent extends StatelessWidget {
  const _ShowChangeContent(this.viewModel);

  final ShowChangeViewModel viewModel;

  List<StoryPageObject> constructPages() {
    if (viewModel.pagesMap == null || viewModel.pagesMap!.keys.isEmpty) return <StoryPageObject>[];
    return List.generate(viewModel.content.richPages?.length ?? 0, (index) {
      final page = viewModel.content.richPages![index];
      return viewModel.pagesMap![page.id];
    }).toList().whereType<StoryPageObject>().toList();
  }

  @override
  Widget build(BuildContext context) {
    List<StoryPageObject> pages = constructPages();

    return Scaffold(
      appBar: AppBar(),
      body: buildBody(context, pages),
    );
  }

  Widget buildBody(BuildContext context, List<StoryPageObject> pages) {
    if (pages.isEmpty) return const Center(child: CircularProgressIndicator.adaptive());

    return StoryPagesBuilder(
      headerBuilder: null,
      preferences: viewModel.params.preferences,
      pageController: viewModel.pageController,
      pages: pages,
      storyContent: viewModel.content,
      padding: EdgeInsets.only(
        left: MediaQuery.viewPaddingOf(context).left,
        right: MediaQuery.viewPaddingOf(context).right,
      ),
      bottomSpacing: 12,
      pageScrollController: null,
    );
  }
}
