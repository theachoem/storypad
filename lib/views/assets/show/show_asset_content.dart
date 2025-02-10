part of 'show_asset_view.dart';

class _ShowAssetContent extends StatelessWidget {
  const _ShowAssetContent(this.viewModel);

  final ShowAssetViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StoryList.withQuery(
        viewOnly: viewModel.params.storyViewOnly,
        filter: SearchFilterObject(
          assetId: viewModel.params.assetId,
          years: {},
          types: {},
          tagId: null,
        ),
      ),
    );
  }
}
