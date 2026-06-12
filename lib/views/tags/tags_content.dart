part of 'tags_view.dart';

class _TagsContent extends StatelessWidget {
  const _TagsContent(this.viewModel);

  final TagsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TagsProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: buildAppBar(provider, context),
            body: TabBarView(
              children: [
                buildCategory(context, provider, categoryId: null),
                buildCategory(context, provider, categoryId: TagCategoryDbModel.peopleId),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar buildAppBar(TagsProvider provider, BuildContext context) {
    return AppBar(
      title: Text(tr("page.tags.title")),
      bottom: TabBar(
        tabs: [
          Tab(text: tr("page.tags.title")),
          Tab(text: tr("general.tag_category.people_title")),
        ],
      ),
      actions: [
        if (viewModel.params.pickMode) ...[
          if (viewModel.params.maxCount != null)
            SpCapacityBadge(
              current: viewModel.selectedTags.length,
              max: viewModel.params.maxCount!,
            ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              final selected =
                  provider.allTags?.items.where((t) => viewModel.selectedTags.contains(t.id)).toList() ?? [];
              Navigator.maybePop(context, selected);
            },
            child: Text(tr('button.done')),
          ),
        ] else
          IconButton(
            tooltip: tr("page.new_tag.title"),
            icon: const Icon(SpIcons.add),
            onPressed: () {
              final categoryId = DefaultTabController.of(context).index == 1 ? TagCategoryDbModel.peopleId : null;
              provider.addTag(context, categoryId: categoryId);
            },
          ),
      ],
    );
  }

  Widget buildCategory(BuildContext context, TagsProvider provider, {required int? categoryId}) {
    return RefreshIndicator.adaptive(
      onRefresh: () => provider.reload(),
      child: buildBody(context, provider, categoryId: categoryId),
    );
  }

  Widget buildBody(BuildContext context, TagsProvider provider, {required int? categoryId}) {
    final collection = provider.tagsOf(categoryId);
    if (collection?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    if (collection?.items.isEmpty == true) {
      return buildEmptyBody(context, categoryId: categoryId);
    }

    return SpScrollConfiguration(
      child: ReorderableListView.builder(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        buildDefaultDragHandles: true,
        itemCount: collection?.items.length ?? 0,
        onReorderItem: (int oldIndex, int newIndex) => provider.reorder(oldIndex, newIndex, categoryId: categoryId),
        proxyDecorator: (child, index, animation) {
          return Container(
            color: Theme.of(context).colorScheme.readOnly.surface5,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final tag = collection!.items[index];
          final storyCount = viewModel.getStoriesCount(tag);

          return Slidable(
            closeOnScroll: true,
            key: ValueKey(tag.id),
            endActionPane: viewModel.params.pickMode
                ? null
                : ActionPane(
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
      tileColor: Colors.transparent,
      contentPadding: !viewModel.checkable
          ? const EdgeInsets.only(left: 16.0, right: 16.0)
          : const EdgeInsets.only(left: 4.0, right: 16.0),
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
      onTap: viewModel.params.pickMode
          ? () async {
              final isSelected = viewModel.selectedTags.contains(tag.id);
              final maxCount = viewModel.params.maxCount;
              if (!isSelected && maxCount != null && viewModel.selectedTags.length >= maxCount) return;
              await viewModel.onToggle(tag, !isSelected);
            }
          : () => provider.viewTag(
              context: context,
              tag: tag,
              storyViewOnly: viewModel.params.storyViewOnly,
            ),
      leading: !viewModel.checkable
          ? null
          : Checkbox.adaptive(
              tristate: false,
              value: viewModel.selectedTags.contains(tag.id),
              onChanged:
                  viewModel.params.pickMode &&
                      viewModel.params.maxCount != null &&
                      viewModel.selectedTags.length >= viewModel.params.maxCount! &&
                      !viewModel.selectedTags.contains(tag.id)
                  ? null
                  : (value) async {
                      await viewModel.onToggle(tag, value!);
                      if (context.mounted && !viewModel.params.pickMode) {
                        context.read<TagsProvider>().reload();
                      }
                    },
            ),
    );
  }

  Widget buildEmptyBody(BuildContext context, {required int? categoryId}) {
    final isPeople = categoryId == TagCategoryDbModel.peopleId;
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
                  Icon(isPeople ? SpIcons.people : SpIcons.tag, size: 32.0),
                  Text(
                    isPeople ? tr("page.tags.people_empty_message") : tr("page.tags.empty_message"),
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
