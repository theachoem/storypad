part of 'show_tag_view.dart';

class _ShowTagAdaptive extends StatelessWidget {
  const _ShowTagAdaptive(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(viewModel.tag.title)),
      body: StoryList.withQuery(
        tagId: viewModel.tag.id,
        viewOnly: viewModel.params.storyViewOnly,
        types: const [
          PathType.archives,
          PathType.docs,
        ],
      ),
    );
  }
}
