part of 'story_changes_view.dart';

class _StoryChangesContent extends StatelessWidget {
  const _StoryChangesContent(this.viewModel);

  final StoryChangesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            [
              tr("page.changes_history.title"),
              if (viewModel.originalStory?.allChanges?.length != null)
                "(${viewModel.originalStory?.allChanges?.length})",
            ].join(" "),
          ),
          actions: [
            Visibility(
              visible: !viewModel.editing,
              child: SpFadeIn.fromBottom(
                child: IconButton(
                  tooltip: tr("button.edit"),
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
            style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).onSecondary),
            text: " ${tr(
              "page.changes_history.too_many_changes_warning_message",
              namedArgs: {'CHANGES_COUNT': allChanges?.length.toString() ?? tr('general.na')},
            )}",
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
            title: tr("button.view"),
            leadingIconData: Icons.book,
            onPressed: () {
              ShowChangeRoute(content: change).push(context);
            },
          ),
          if (!isLatestChange)
            SpPopMenuItem(
              leadingIconData: Icons.restore,
              title: tr("button.restore_this_version"),
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
          title: Text(change.title ?? tr("general.na")),
          contentPadding: isLatestChange
              ? const EdgeInsets.symmetric(horizontal: 16.0)
              : const EdgeInsets.only(left: 16.0, right: 4.0),
          trailing: trailing,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatService.yMEd_jm(change.createdAt, context.locale),
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
                      onPressed: () => viewModel.turnOffEditing(),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: ColorScheme.of(context).error),
                      child: Text("${tr("button.delete")} (${viewModel.toBeRemovedCount})"),
                      onPressed: () => viewModel.remove(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
