part of 'show_asset_view.dart';

class _ShowAssetAdaptive extends StatelessWidget {
  const _ShowAssetAdaptive(this.viewModel);

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
