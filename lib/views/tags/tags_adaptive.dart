part of 'tags_view.dart';

class _TagsAdaptive extends StatelessWidget {
  const _TagsAdaptive(this.viewModel);

  final TagsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TagsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tags"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => provider.addTag(context),
          )
        ],
      ),
      body: buildBody(
        context,
        provider,
      ),
    );
  }

  Widget buildBody(BuildContext context, TagsProvider provider) {
    if (provider.tags?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    if (provider.tags?.items.isEmpty == true) {
      return buildEmptyBody(context);
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: provider.tags?.items.length ?? 0,
      onReorder: (int oldIndex, int newIndex) => provider.reorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final tag = provider.tags!.items[index];
        final storyCount = provider.getStoriesCount(tag);

        return Theme(
          key: ValueKey(tag.id),
          // Remove theme wrapper here when this is fixed:
          // https://github.com/letsar/flutter_slidable/issues/512
          data: Theme.of(context).copyWith(
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(iconColor: WidgetStatePropertyAll(ColorScheme.of(context).onError)),
            ),
          ),
          child: Slidable(
            closeOnScroll: true,
            key: ValueKey(tag.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => provider.deleteTag(context, tag),
                  backgroundColor: ColorScheme.of(context).error,
                  foregroundColor: ColorScheme.of(context).onError,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
                SlidableAction(
                  onPressed: (context) => provider.editTag(context, tag),
                  backgroundColor: ColorScheme.of(context).secondary,
                  foregroundColor: ColorScheme.of(context).onSecondary,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.drag_indicator),
              title: Text(tag.title),
              subtitle: Text(storyCount > 1 ? "$storyCount stories" : "$storyCount story"),
              onTap: () => provider.viewTag(context: context, tag: tag, storyViewOnly: viewModel.params.storyViewOnly),
            ),
          ),
        );
      },
    );
  }

  Widget buildEmptyBody(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 200),
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kToolbarHeight),
            child: Text(
              "Tags will appear here",
              textAlign: TextAlign.center,
              style: TextTheme.of(context).bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
