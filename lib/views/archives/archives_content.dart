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
              actions: [buildEditButton(context)],
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
          child: SpFadeIn.fromBottom(
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
              style: TextTheme.of(context).titleLarge,
              text: viewModel.type.localized,
              children: const [
                WidgetSpan(child: Icon(Icons.arrow_drop_down)),
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
                          style: FilledButton.styleFrom(backgroundColor: ColorScheme.of(context).error),
                          child: Text("${tr("button.delete")} (${state.selectedStories.length})"),
                          onPressed: () async {
                            OkCancelResult result = await showOkCancelAlertDialog(
                              context: context,
                              title: tr("dialog.are_you_sure_to_delete_these_stories.title"),
                              message: tr("dialog.are_you_sure_to_delete_these_stories.message"),
                              isDestructiveAction: true,
                              okLabel: tr("button.delete"),
                            );

                            if (result == OkCancelResult.ok) {
                              for (int i = 0; i < state.selectedStories.length; i++) {
                                int id = state.selectedStories.elementAt(i);
                                await StoryDbModel.db.delete(id, runCallbacks: i == state.selectedStories.length - 1);
                              }
                              state.turnOffEditing();
                            }
                          },
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
}
