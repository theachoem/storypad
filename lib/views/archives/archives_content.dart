part of 'archives_view.dart';

class _ArchivesContent extends StatelessWidget {
  const _ArchivesContent(this.viewModel);

  final ArchivesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StoryListMultiEditWrapper(
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
          child: Scaffold(
            appBar: AppBar(
              title: buildTitle(context),
              actions: [
                buildEditButton(context),
                buildMoreEditingOptionsButton(context),
              ],
            ),
            bottomNavigationBar: buildBottomNavigationBar(context),
            body: StoryList.withQuery(
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

  Widget buildEditButton(BuildContext context) {
    return StoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return Visibility(
          visible: !state.editing,
          child: SpFadeIn.fromRight(
            child: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => state.turnOnEditing(),
            ),
          ),
        );
      },
    );
  }

  Widget buildTitle(BuildContext context) {
    return SpPopupMenuButton(
      dyGetter: (dy) => dy + 48,
      dxGetter: (dx) => dx - 48.0,
      items: (context) {
        return [PathType.archives, PathType.bins].map((type) {
          return SpPopMenuItem(
            selected: type == viewModel.type,
            title: type.localized,
            onPressed: () {
              context.read<StoryListMultiEditWrapperState>().turnOffEditing();
              viewModel.setType(type);
            },
          );
        }).toList();
      },
      builder: (open) {
        return SpTapEffect(
          onTap: open,
          child: RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              text: viewModel.type.localized,
              style: TextTheme.of(context).titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: viewModel.type.isArchives ? ColorScheme.of(context).primary : ColorScheme.of(context).error,
                  ),
              children: const [
                WidgetSpan(child: Icon(Icons.arrow_drop_down), alignment: PlaceholderAlignment.middle),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return StoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return Visibility(
          visible: state.editing,
          child: SpFadeIn.fromBottom(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
                        .add(EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)),
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8.0,
                      children: [
                        FilledButton.tonal(
                          child: Text(tr("button.cancel")),
                          onPressed: () => state.turnOffEditing(),
                        ),
                        FilledButton(
                          style: viewModel.type.isBins
                              ? FilledButton.styleFrom(backgroundColor: ColorScheme.of(context).error)
                              : null,
                          child: Text(
                            "${viewModel.type.isBins ? tr("button.permanent_delete") : tr("button.move_to_bin")} (${state.selectedStories.length})",
                          ),
                          onPressed: () => viewModel.type.isBins
                              ? viewModel.permanantDeleteAll(context)
                              : viewModel.moveToBinAll(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMoreEditingOptionsButton(BuildContext context) {
    return StoryListMultiEditWrapper.listen(
      context: context,
      builder: (context, state) {
        return Visibility(
          visible: state.selectedStories.isNotEmpty,
          child: SpFadeIn.fromRight(
            child: SpPopupMenuButton(
              items: (BuildContext context) {
                return [
                  SpPopMenuItem(
                    title: tr("button.put_back_all"),
                    leadingIconData: Icons.settings_backup_restore,
                    onPressed: () => viewModel.putBackAll(context),
                  ),
                  if (viewModel.type.isArchives)
                    SpPopMenuItem(
                      title: tr("button.move_to_bin_all"),
                      leadingIconData: Icons.delete,
                      onPressed: () => viewModel.moveToBinAll(context),
                    ),
                  // for bin, "delete all" already show in bottom nav.
                  if (viewModel.type.isArchives)
                    SpPopMenuItem(
                      title: tr("button.permanent_delete_all"),
                      leadingIconData: Icons.delete_forever,
                      titleStyle: TextStyle(color: ColorScheme.of(context).error),
                      onPressed: () => viewModel.permanantDeleteAll(context),
                    ),
                ];
              },
              builder: (callback) {
                return IconButton(
                  icon: Icon(Icons.more_vert),
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
