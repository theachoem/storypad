part of 'search_view.dart';

class _SearchContent extends StatelessWidget {
  const _SearchContent(this.viewModel);

  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpStoryListMultiEditWrapper(
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
        title: TextField(
          textInputAction: TextInputAction.search,
          style: Theme.of(context).appBarTheme.titleTextStyle,
          keyboardType: TextInputType.text,
          autofocus: false,
          decoration: InputDecoration(
            hintText: tr("input.story_search.hint"),
            border: InputBorder.none,
          ),
          onChanged: (value) => viewModel.search(value),
          onSubmitted: (value) => viewModel.search(value),
        ),
        actions: [
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(SpIcons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
      body: ValueListenableBuilder<String>(
        valueListenable: viewModel.queryNotifier,
        builder: (context, query, child) {
          return SpStoryList.withQuery(
            query: query,
            filter: viewModel.filter,
          );
        },
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return SpStoryListMultiEditWrapper.listen(
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
