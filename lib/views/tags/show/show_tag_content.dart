part of 'show_tag_view.dart';

class _ShowTagContent extends StatelessWidget {
  const _ShowTagContent(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StoryListMultiEditWrapper(
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
          child: buildScaffold(context),
        );
      },
    );
  }

  Widget buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildTitle(context),
        actions: [
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(Icons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
      body: StoryList.withQuery(
        viewOnly: viewModel.params.storyViewOnly,
        filter: viewModel.filter,
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return SpTapEffect(
      onTap: () => viewModel.goToEditPage(context),
      child: RichText(
        text: TextSpan(
          text: "${viewModel.tag.title} ",
          style: TextTheme.of(context).titleLarge,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.edit_outlined,
                size: 20.0,
                color: ColorScheme.of(context).primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return StoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
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
      },
    );
  }
}
