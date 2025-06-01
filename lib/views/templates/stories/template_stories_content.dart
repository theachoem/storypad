part of 'template_stories_view.dart';

class _TemplateStoriesContent extends StatelessWidget {
  const _TemplateStoriesContent(this.viewModel);

  final TemplateStoriesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpStoryListMultiEditWrapper(
      disabled: true,
      builder: (BuildContext context) {
        return buildScaffold(context);
      },
    );
  }

  Widget buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SpStoryList.withQuery(
        viewOnly: true,
        filter: viewModel.filter,
      ),
    );
  }
}
