part of 'show_table_view.dart';

class _ShowTableContent extends StatelessWidget {
  const _ShowTableContent(this.viewModel);

  final ShowTableViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    Widget viewer;

    switch (viewModel.params.tableName) {
      case 'stories':
        List<StoryDbModel> models = viewModel.params.tableContents
            .map((e) => StoriesBox().modelFromJson(e)..markAsCloudViewing())
            .toList();
        viewer = BackupStoriesTableViewer(stories: models);
        break;
      case 'tags':
        List<TagDbModel> models = viewModel.params.tableContents
            .map((e) => TagsBox().modelFromJson(e)..markAsCloudViewing())
            .toList();
        viewer = BackupTagsTableViewer(tags: models);
        break;
      case 'preferences':
        List<PreferenceDbModel> models = viewModel.params.tableContents
            .map((e) => PreferencesBox().modelFromJson(e)..markAsCloudViewing())
            .toList();
        viewer = BackupPreferencesTableViewer(preferences: models);
        break;
      case 'assets':
        List<AssetDbModel> models = viewModel.params.tableContents
            .map((e) => AssetsBox().modelFromJson(e)..markAsCloudViewing())
            .toList();
        viewer = BackupAssetsTableViewer(assets: models);
        break;
      default:
        viewer = BackupDefaultTableViewer(tableContents: viewModel.params.tableContents);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.params.translateTabledName),
      ),
      body: viewer,
    );
  }
}
