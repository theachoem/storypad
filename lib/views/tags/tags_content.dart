part of 'tags_view.dart';

class _TagsContent extends StatelessWidget {
  const _TagsContent(this.viewModel);

  final TagsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TagsProvider>(context);

    return Column(
      children: [
        buildSearchBar(context, provider),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator.adaptive(
            onRefresh: () => viewModel.load(),
            child: buildBody(context, provider),
          ),
        ),
      ],
    );
  }

  Widget buildSearchBar(BuildContext context, TagsProvider provider) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 8.0, bottom: 12.0),
      child: SearchAnchor.bar(
        barBackgroundColor: WidgetStatePropertyAll(ColorScheme.of(context).surface),
        barElevation: const WidgetStatePropertyAll(0.0),
        barShape: WidgetStatePropertyAll(
          StadiumBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        isFullScreen: true,
        barLeading: const Icon(SpIcons.search),
        barHintText: tr("button.search"),
        suggestionsBuilder: (context, controller) {
          final query = controller.text.trim();
          final allItems = provider.tags?.items ?? [];

          final bool allowCreate =
              query.isNotEmpty && !allItems.any((t) => t.title.toLowerCase() == query.toLowerCase());

          List<TagDbModel> filtered;
          if (query.isEmpty) {
            filtered = allItems;
          } else {
            final fuzzy = Fuzzy<TagDbModel>(
              allItems,
              options: FuzzyOptions(
                isCaseSensitive: false,
                keys: [WeightedKey(name: 'title', getter: (t) => t.title, weight: 1)],
              ),
            );
            final results = fuzzy.search(query);
            results.sort((a, b) => a.score.compareTo(b.score));
            filtered = results.map((r) => r.item).toList();
          }

          return [
            ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allowCreate)
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
                        leading: const Icon(SpIcons.add),
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${tr("page.new_tag.title")}: '),
                              TextSpan(
                                text: '"$query"',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        onTap: () async {
                          final tag = await provider.createTag(query);
                          if (tag != null && context.mounted) {
                            if (viewModel.checkable) await viewModel.onToggle(tag, true);
                            controller.closeView(null);
                            if (context.mounted) viewModel.load();
                          }
                        },
                      ),
                    ...filtered.map((tag) => buildTile(tag, viewModel.getStoriesCount(tag), provider, context)),
                  ],
                );
              },
            ),
          ];
        },
      ),
    );
  }

  Widget buildBody(BuildContext context, TagsProvider provider) {
    if (provider.tags?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    final items = provider.tags!.items;
    if (items.isEmpty) return buildEmptyBody(context);

    return SpScrollConfiguration(
      child: ReorderableListView.builder(
        padding: EdgeInsets.only(
          bottom: (viewModel.params.bottomPadding ?? MediaQuery.of(context).padding.bottom) + 16.0,
        ),
        buildDefaultDragHandles: true,
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) => provider.reorder(oldIndex, newIndex),
        proxyDecorator: (child, index, animation) {
          return Container(
            color: Theme.of(context).colorScheme.readOnly.surface5,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final tag = items[index];
          final storyCount = viewModel.getStoriesCount(tag);

          return Slidable(
            closeOnScroll: true,
            key: ValueKey(tag.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => provider.deleteTag(context, tag),
                  backgroundColor: ColorScheme.of(context).error,
                  foregroundColor: ColorScheme.of(context).onError,
                  icon: SpIcons.delete,
                  label: tr("button.delete"),
                ),
                SlidableAction(
                  onPressed: (context) => provider.editTag(context, tag),
                  backgroundColor: ColorScheme.of(context).secondary,
                  foregroundColor: ColorScheme.of(context).onSecondary,
                  icon: SpIcons.edit,
                  label: tr("button.edit"),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: buildTile(tag, storyCount, provider, context),
            ),
          );
        },
      ),
    );
  }

  Widget buildTile(
    TagDbModel tag,
    int storyCount,
    TagsProvider provider,
    BuildContext context,
  ) {
    return ListTile(
      key: ValueKey(tag.id),
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.only(
        left: viewModel.checkable ? 4.0 : 16.0,
        right: 16.0,
      ),
      leading: viewModel.checkable
          ? Checkbox.adaptive(
              tristate: false,
              value: viewModel.selectedTags.contains(tag.id),
              onChanged: (value) async {
                await viewModel.onToggle(tag, value!);
                if (context.mounted) viewModel.load();
              },
            )
          : null,
      title: Text(tag.title),
      subtitle: Text(plural("plural.story", storyCount)),
      trailing:
          [
            TargetPlatform.linux,
            TargetPlatform.windows,
            TargetPlatform.macOS,
          ].contains(Theme.of(context).platform)
          ? null
          : const Icon(SpIcons.dragIndicator),
      onTap: () {
        if (viewModel.checkable) {
          viewModel.onToggle(tag, !viewModel.selectedTags.contains(tag.id)).then((_) {
            if (context.mounted) viewModel.load();
          });
        } else {
          provider.viewTag(
            context: context,
            tag: tag,
            storyViewOnly: viewModel.params.storyViewOnly,
          );
        }
      },
    );
  }

  Widget buildEmptyBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: constraints.maxHeight,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12.0,
                children: [
                  const Icon(SpIcons.tag, size: 32.0),
                  Text(
                    tr("page.tags.empty_message"),
                    textAlign: TextAlign.center,
                    style: TextTheme.of(context).bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
