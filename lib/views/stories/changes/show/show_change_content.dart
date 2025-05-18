part of 'show_change_view.dart';

class _ShowChangeContent extends StatelessWidget {
  const _ShowChangeContent(this.viewModel);

  final ShowChangeViewModel viewModel;

  List<StoryPageObject> constructPages() {
    if (viewModel.pagesMap == null || viewModel.pagesMap!.keys.isEmpty) return <StoryPageObject>[];
    return List.generate(viewModel.content.richPages?.length ?? 0, (index) {
      final page = viewModel.content.richPages![index];
      return viewModel.pagesMap![page.id]!;
    }).toList();
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
      viewInsets: MediaQuery.viewInsetsOf(context),
      header: null,
      preferences: null,
      pages: pages,
      storyContent: viewModel.content,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      pageScrollController: null,
    );
  }
}
