part of 'tags_view.dart';

class _TagsAdaptive extends StatelessWidget {
  const _TagsAdaptive(this.viewModel);

  final TagsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tags"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => viewModel.addTag(context),
          )
        ],
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.tags?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    if (viewModel.tags?.items.isEmpty == true) {
      return buildEmptyBody(context);
    }

    return ListView.builder(
      itemCount: viewModel.tags?.items.length ?? 0,
      itemBuilder: (context, index) {
        final tag = viewModel.tags!.items[index];
        final storyCount = tag.storiesCount ?? 0;

        return Theme(
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
                  onPressed: (context) => viewModel.deleteTag(context, tag),
                  backgroundColor: ColorScheme.of(context).error,
                  foregroundColor: ColorScheme.of(context).onError,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
                SlidableAction(
                  onPressed: (context) => viewModel.editTag(context, tag),
                  backgroundColor: ColorScheme.of(context).secondary,
                  foregroundColor: ColorScheme.of(context).onSecondary,
                  icon: Icons.edit,
                  label: 'Edit',
                ),
              ],
            ),
            child: ListTile(
              title: Text(tag.title),
              subtitle: Text(storyCount > 1 ? "$storyCount stories" : "$storyCount story"),
              onTap: () => viewModel.viewTag(context, tag),
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
