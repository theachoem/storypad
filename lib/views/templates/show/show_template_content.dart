part of 'show_template_view.dart';

class _ShowTemplateContent extends StatelessWidget {
  const _ShowTemplateContent(this.viewModel);

  final ShowTemplateViewModel viewModel;

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
