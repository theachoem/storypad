part of 'tags_view.dart';

class _TagsContent extends StatelessWidget {
  const _TagsContent(this.viewModel);

  final TagsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TagsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.tags.title")),
        actions: [
          IconButton(
            tooltip: tr("page.new_tag.title"),
            icon: const Icon(SpIcons.add),
            onPressed: () => provider.addTag(context),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => provider.reload(),
        child: buildBody(
          context,
          provider,
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context, TagsProvider provider) {
    if (provider.tags?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    if (provider.tags?.items.isEmpty == true) {
      return buildEmptyBody(context);
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
      ),
      itemCount: provider.tags?.items.length ?? 0,
      onReorder: (int oldIndex, int newIndex) => provider.reorder(oldIndex, newIndex),
      proxyDecorator: (child, index, animation) {
        return Container(
          color: Theme.of(context).colorScheme.readOnly.surface5,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final tag = provider.tags!.items[index];
        final storyCount = provider.getStoriesCount(tag);

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
          child: buildTile(tag, storyCount, provider, context),
        );
      },
    );
  }

  Widget buildTile(TagDbModel tag, int storyCount, TagsProvider provider, BuildContext context) {
    return ListTile(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.only(left: 16.0, right: 4.0),
      leading: const Icon(SpIcons.dragIndicator),
      title: Text(tag.title),
      subtitle: Text(plural("plural.story", storyCount)),
      onTap: () => provider.viewTag(
        context: context,
        tag: tag,
        storyViewOnly: viewModel.params.storyViewOnly,
      ),
      trailing: !viewModel.checkable
          ? null
          : Checkbox.adaptive(
              tristate: false,
              value: viewModel.selectedTags.contains(tag.id),
              onChanged: (value) async {
                await viewModel.onToggle(tag, value!);
                if (context.mounted) context.read<TagsProvider>().reload();
              },
            ),
    );
  }

  Widget buildEmptyBody(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
    });
  }
}
