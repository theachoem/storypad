part of 'show_tag_view.dart';

class _ShowTagContent extends StatelessWidget {
  const _ShowTagContent(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpStoryListMultiEditWrapper.withListener(
      builder: (BuildContext context, SpStoryListMultiEditWrapperState state) {
        return PopScope(
          canPop: !state.editing,
          onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
          child: buildScaffold(context, state),
        );
      },
    );
  }

  Widget buildScaffold(BuildContext context, SpStoryListMultiEditWrapperState state) {
    return Scaffold(
      appBar: AppBar(
        title: buildTitle(context),
        actions: [
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(SpIcons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, state),
      body: SpStoryList.withQuery(
        viewOnly: viewModel.params.storyViewOnly,
        filter: viewModel.filter,
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return SpTapEffect(
      onTap: () => viewModel.goToEditPage(context),
      child: Text.rich(
        TextSpan(
          text: "${viewModel.tag.title} ",
          style: TextTheme.of(context).titleLarge,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                SpIcons.edit,
                size: 20.0,
                color: ColorScheme.of(context).primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context, SpStoryListMultiEditWrapperState state) {
    return SpMultiEditBottomNavBar(
      editing: state.editing,
      onCancel: () => state.turnOffEditing(),
      buttons: [
        OutlinedButton(
          child: Text("${tr("button.archive")} (${state.selectedStories.length})"),
          onPressed: () => state.archiveAll(context),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ColorScheme.of(context).error),
          child: Text("${tr("button.move_to_bin")} (${state.selectedStories.length})"),
          onPressed: () => state.moveToBinAll(context),
        ),
      ],
    );
  }
}
