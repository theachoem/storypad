part of 'show_tag_view.dart';

class _ShowTagAdaptive extends StatelessWidget {
  const _ShowTagAdaptive(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(viewModel.tag.title)),
      body: StoryList.withQuery(
        viewOnly: viewModel.params.storyViewOnly,
        filter: SearchFilterObject(
          years: {},
          types: {PathType.archives, PathType.docs},
          tagId: viewModel.tag.id,
        ),
      ),
    );
  }
}
