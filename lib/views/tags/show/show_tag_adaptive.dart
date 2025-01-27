part of 'show_tag_view.dart';

class _ShowTagAdaptive extends StatelessWidget {
  const _ShowTagAdaptive(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.tag.title),
        actions: [
          IconButton(
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
