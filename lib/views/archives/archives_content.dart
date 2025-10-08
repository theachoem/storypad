part of 'archives_view.dart';

class _ArchivesContent extends StatelessWidget {
  const _ArchivesContent(this.viewModel);

  final ArchivesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpStoryListMultiEditWrapper.withListener(
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
            ),
            bottomNavigationBar: buildBottomNavigationBar(context),
            body: SpStoryList.withQuery(
              key: ValueKey(viewModel.editedKey),
              viewOnly: true,
              filter: SearchFilterObject(
                years: {},
                types: {viewModel.type},
                tagId: null,
                assetId: null,
              ),
            ),
          ),
        );
      },
    );
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
    Widget buildType({
      required PathType type,
    }) {
      return Text(
        type.localized,
        style: TextTheme.of(context).titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: type.isArchives ? ColorScheme.of(context).primary : ColorScheme.of(context).error,
        ),
      );
    }

    return GestureDetector(
      onTap: () => viewModel.setType(viewModel.type.isArchives ? PathType.bins : PathType.archives),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        runAlignment: WrapAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          SpCrossFade(
            showFirst: viewModel.type == PathType.bins,
            firstChild: buildType(type: PathType.bins),
            secondChild: buildType(type: PathType.archives),
          ),
          Icon(
            SpIcons.swapHoriz,
            size: 24.0,
            color: viewModel.type.isArchives ? ColorScheme.of(context).primary : ColorScheme.of(context).error,
          ),
        ],
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
