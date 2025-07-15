part of 'recently_deleted_records_view.dart';

class _RecentlyDeletedRecordsContent extends StatelessWidget {
  const _RecentlyDeletedRecordsContent(this.viewModel);

  final RecentlyDeletedRecordsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deleted Records"),
      ),
      body: SpStoryListMultiEditWrapper(
        disabled: true,
        builder: (BuildContext context) {
          return SpStoryList(
            viewOnly: true,
            stories: viewModel.deleteRecords,
            onChanged: (_) => viewModel.load(),
            onDeleted: () {},
          );
        },
      ),
    );
  }
}
