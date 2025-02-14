part of 'show_tag_view.dart';

class _ShowTagContent extends StatelessWidget {
  const _ShowTagContent(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.tag.title),
        actions: [
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(Icons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
      ),
      body: StoryList.withQuery(
        viewOnly: viewModel.params.storyViewOnly,
        filter: viewModel.filter,
      ),
    );
  }
}
