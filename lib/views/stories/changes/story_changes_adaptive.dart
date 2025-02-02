part of 'story_changes_view.dart';

class _StoryChangesAdaptive extends StatelessWidget {
  const _StoryChangesAdaptive(this.viewModel);

  final StoryChangesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
      child: Scaffold(
        appBar: AppBar(
          title: viewModel.originalStory?.allChanges?.length != null
              ? Text("Changes (${viewModel.originalStory?.allChanges?.length})")
              : const Text("Changes"),
          actions: [
            Visibility(
              visible: !viewModel.editing,
              child: SpFadeIn.fromBottom(
                child: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => viewModel.turnOnEditing(),
                ),
              ),
            ),
          ],
        ),
        body: buildBody(context),
        bottomNavigationBar: buildBottomNavigationBar(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.draftStory == null) return const Center(child: CircularProgressIndicator.adaptive());
    List<StoryContentDbModel>? allChanges = viewModel.draftStory?.allChanges?.reversed.toList();

    return Column(
      children: [
        if (allChanges?.length != null && allChanges!.length > 20) buildWarningBanner(context, allChanges),
        Expanded(
          child: ListView.separated(
            itemCount: allChanges?.length ?? 0,
            separatorBuilder: (context, index) => const Divider(height: 1),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            itemBuilder: (context, index) {
              StoryContentDbModel change = allChanges![index];
              bool isLatestChange = viewModel.draftStory?.latestChange?.id == change.id;
              return buildChangeTile(change, isLatestChange, context);
            },
          ),
        ),
      ],
    );
  }

  Widget buildWarningBanner(BuildContext context, List<StoryContentDbModel>? allChanges) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: ColorScheme.of(context).secondary,
      width: double.infinity,
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(children: [
          WidgetSpan(child: Icon(Icons.info, size: 16.0, color: ColorScheme.of(context).onSecondary)),
          TextSpan(
            text: " You have ${allChanges?.length} changes stored, using a lot of space. You should remove some.",
            style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).onSecondary),
          )
        ]),
      ),
    );
  }

  Widget buildChangeTile(StoryContentDbModel change, bool isLatestChange, BuildContext context) {
    return SpPopupMenuButton(
      smartDx: true,
      dyGetter: (dy) => dy + 88,
      items: (context) {
        return [
          SpPopMenuItem(
            title: "View",
            leadingIconData: Icons.book,
            onPressed: () {
              ShowChangeRoute(content: change).push(context);
            },
          ),
          if (!isLatestChange)
            SpPopMenuItem(
              leadingIconData: Icons.restore,
              title: "Restore this version",
              onPressed: () => viewModel.restore(context, change),
            ),
        ];
      },
      builder: (open) {
        Widget? trailing;
        if (isLatestChange) {
          trailing = const Icon(Icons.lock);
        } else {
          trailing = viewModel.editing
              ? Checkbox.adaptive(
                  value: viewModel.selectedChanges.contains(change.id),
                  onChanged: (_) => viewModel.toggleSelection(change),
                )
              : null;
        }

        return ListTile(
          onLongPress: () {
            viewModel.turnOnEditing();
            if (!isLatestChange) {
              viewModel.toggleSelection(change);
            }
          },
          onTap: () {
            if (viewModel.editing) {
              if (isLatestChange) return;
              viewModel.toggleSelection(change);
            } else {
              open();
            }
          },
          isThreeLine: true,
          title: Text(change.title ?? 'N/A'),
          contentPadding: isLatestChange
              ? const EdgeInsets.symmetric(horizontal: 16.0)
              : const EdgeInsets.only(left: 16.0, right: 4.0),
          trailing: trailing,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatService.yMEd_jm(change.createdAt),
                style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).primary),
              ),
              const SizedBox(height: 4.0),
              SpMarkdownBody(body: change.displayShortBody!)
            ],
          ),
        );
      },
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return Visibility(
      visible: viewModel.editing,
      child: SpFadeIn.fromBottom(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
                  .add(EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8.0,
                children: [
                  FilledButton.tonal(
                    child: const Text("Cancel"),
                    onPressed: () => viewModel.turnOffEditing(),
                  ),
                  FilledButton(
                    child: Text("Remove (${viewModel.toBeRemovedCount})"),
                    onPressed: () => viewModel.remove(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
