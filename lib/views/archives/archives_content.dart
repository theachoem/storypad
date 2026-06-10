part of 'archives_view.dart';

class _ArchivesContent extends StatelessWidget {
  const _ArchivesContent(this.viewModel);

  final ArchivesViewModel viewModel;

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
            child: Scaffold(
              appBar: AppBar(
                title: buildTitle(context),
                actions: [
                  buildEditButton(context, state),
                  buildMoreEditingOptionsButton(context),
                ],
                bottom: years == null
                    ? null
                    : TabBar(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        onTap: (_) => state.turnOffEditing(),
                        tabs: years.map((y) => Tab(text: y.toString())).toList(),
                      ),
              ),
              bottomNavigationBar: buildBottomNavigationBar(context),
              body: buildBody(years),
            ),
          );
        },
      ),
    );
  }

  Widget buildBody(List<int>? years) {
    if (years == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    } else {
      return TabBarView(
        children: years.map((year) {
          return SpStoryList.withQuery(
            key: ValueKey('${viewModel.editedKey}_$year'),
            viewOnly: true,
            filter: SearchFilterObject(
              years: {year},
              types: {viewModel.type},
              assetId: null,
            ),
          );
        }).toList(),
      );
    }
  }

  Widget buildEditButton(BuildContext context, SpStoryListMultiEditWrapperState state) {
    return Visibility(
      visible: !state.editing,
      child: SpFadeIn.fromRight(
        child: IconButton(
          tooltip: tr("button.edit"),
          icon: const Icon(SpIcons.edit),
          onPressed: () => state.turnOnEditing(),
        ),
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    return Text(
      viewModel.params.pathType.localized,
      style: TextTheme.of(context).titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: viewModel.params.pathType.isArchives ? ColorScheme.of(context).primary : ColorScheme.of(context).error,
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
            if (viewModel.type.isBins)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ColorScheme.of(context).error),
                child: Text("${tr("button.permanent_delete")} (${state.selectedStories.length})"),
                onPressed: () async {
                  await state.permanantDeleteAll(context);
                  viewModel.refreshList();
                },
              ),
            if (viewModel.type.isArchives)
              FilledButton(
                child: Text("${tr("button.move_to_bin")} (${state.selectedStories.length})"),
                onPressed: () async {
                  await state.moveToBinAll(context);
                  viewModel.refreshList();
                },
              ),
          ],
        );
      },
    );
  }

  Widget buildMoreEditingOptionsButton(BuildContext context) {
    return SpStoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return Visibility(
          visible: state.editing,
          child: SpFadeIn.fromRight(
            child: SpPopupMenuButton(
              items: (BuildContext context) {
                return [
                  SpPopMenuItem(
                    title: state.selectedStories.length == state.stories.length
                        ? tr('button.unselect_all')
                        : tr("button.select_all"),
                    leadingIconData: state.selectedStories.length == state.stories.length
                        ? SpIcons.checkboxBlank
                        : SpIcons.checkbox,
                    onPressed: () => state.toggleSelectAll(context),
                  ),
                  if (state.selectedStories.isNotEmpty)
                    SpPopMenuItem(
                      title: tr("button.put_back_all"),
                      leadingIconData: SpIcons.putBack,
                      onPressed: () async {
                        await state.putBackAll(context);
                        viewModel.refreshList();
                      },
                    ),
                  if (viewModel.type.isArchives && state.selectedStories.isNotEmpty)
                    SpPopMenuItem(
                      title: tr("button.move_to_bin_all"),
                      leadingIconData: SpIcons.delete,
                      onPressed: () async {
                        await state.moveToBinAll(context);
                        viewModel.refreshList();
                      },
                    ),
                  // for bin, "delete all" already show in bottom nav.
                  if (viewModel.type.isArchives && state.selectedStories.isNotEmpty)
                    SpPopMenuItem(
                      title: tr("button.permanent_delete_all"),
                      leadingIconData: SpIcons.deleteForever,
                      titleStyle: TextStyle(color: ColorScheme.of(context).error),
                      onPressed: () async {
                        await state.permanantDeleteAll(context);
                        viewModel.refreshList();
                      },
                    ),
                ];
              },
              builder: (callback) {
                return IconButton(
                  tooltip: tr("button.more_options"),
                  icon: const Icon(SpIcons.moreVert),
                  onPressed: callback,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
