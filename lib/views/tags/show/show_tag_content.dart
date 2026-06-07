part of 'show_tag_view.dart';

class _ShowTagContent extends StatelessWidget {
  const _ShowTagContent(this.viewModel);

  final ShowTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final years = viewModel.years;

    return DefaultTabController(
      length: years?.length ?? 1,
      child: SpStoryListMultiEditWrapper.withListener(
        builder: (BuildContext context, SpStoryListMultiEditWrapperState state) {
          return PopScope(
            canPop: !state.editing,
            onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
            child: buildScaffold(context, state, years),
          );
        },
      ),
    );
  }

  Widget buildScaffold(BuildContext context, SpStoryListMultiEditWrapperState state, List<int>? years) {
    return Scaffold(
      appBar: AppBar(
        title: buildTitle(context),
        actions: [
          IconButton(
            tooltip: tr("page.search.title"),
            icon: const Icon(SpIcons.search),
            onPressed: () => viewModel.goToSearchPage(context),
          ),
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(SpIcons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
        ],
        bottom: years == null
            ? null
            : TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                onTap: (_) => state.turnOffEditing(),
                tabs: years.map((year) => Tab(text: year.toString())).toList(),
              ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, state),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: FloatingActionButton(
        tooltip: tr("button.new_story"),
        child: const Icon(SpIcons.newStory),
        onPressed: () => viewModel.goToNewPage(context),
      ),
      body: buildBody(years),
    );
  }

  Widget buildBody(List<int>? years) {
    if (years == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return TabBarView(
      children: years.map((year) {
        return SpStoryList.withQuery(
          key: ValueKey('${viewModel.editedKey}_$year'),
          viewOnly: viewModel.params.storyViewOnly,
          filter: viewModel.filter.copyWith(years: {year}),
        );
      }).toList(),
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
