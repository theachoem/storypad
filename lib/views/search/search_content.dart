part of 'search_view.dart';

class _SearchContent extends StatelessWidget {
  const _SearchContent(this.viewModel);

  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpStoryListMultiEditWrapper.withListener(
      builder: (context, state) {
        return PopScope(
          canPop: !state.editing,
          onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
          child: Stack(
            children: [
              buildScaffold(context, state),
              SpSideBarTogglerButton.buildViewButton(
                viewContext: context,
                open: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildScaffold(BuildContext context, SpStoryListMultiEditWrapperState state) {
    var visibleTags = viewModel.tags?.where((tag) => tag.storiesCount != null && tag.storiesCount! > 0).toList();
    if (visibleTags?.isEmpty == true) visibleTags = viewModel.tags;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        title: TextField(
          controller: viewModel.queryController,
          focusNode: viewModel.queryFocusNode,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).appBarTheme.titleTextStyle,
          keyboardType: TextInputType.text,
          autofocus: false,
          decoration: InputDecoration(
            hintText: tr("input.story_search.hint"),
            border: InputBorder.none,
          ),
          onChanged: (value) => viewModel.searchText(value),
          onSubmitted: (value) => viewModel.searchText(value),
        ),
        actions: [
          Visibility(
            visible: viewModel.hasQuery,
            child: IconButton(
              tooltip: tr("button.clear"),
              icon: const Icon(SpIcons.backspace),
              onPressed: () => viewModel.clearQuery(context),
            ),
          ),
          IconButton(
            tooltip: tr("page.search_filter.title"),
            icon: Icon(SpIcons.tune),
            onPressed: () => viewModel.goToFilterPage(context),
          ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
        bottom: visibleTags?.isNotEmpty == true
            ? PreferredSize(
                preferredSize: const Size.fromHeight(34.0 + 12.0 + 1.0),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SpScrollableChoiceChips<TagDbModel>(
                      autoScrollToSelectedOnChanged: true,
                      choices: visibleTags ?? [],
                      storiesCount: (TagDbModel tag) => tag.storiesCount,
                      toLabel: (TagDbModel tag) => tag.title,
                      selected: (TagDbModel tag) => viewModel.searchFilter?.tagId == tag.id,
                      onToggle: (TagDbModel tag) => viewModel.toggleTag(tag, context),
                    ),
                    const SizedBox(height: 12.0),
                    const Divider(height: 1),
                  ],
                ),
              )
            : null,
      ),
      bottomNavigationBar: buildBottomNavigationBar(context, state),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (viewModel.searchFilter == null) return const Center(child: CircularProgressIndicator.adaptive());
    return SpStoryList.withQuery(
      filter: viewModel.searchFilter,
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
