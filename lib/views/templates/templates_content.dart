part of 'templates_view.dart';

class _TemplatesContent extends StatelessWidget {
  const _TemplatesContent(this.viewModel);

  final TemplatesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          viewModel.params.viewingArchives ? tr('general.path_type.archives') : tr("add_ons.templates.title"),
        ),
        actions: [
          if (!viewModel.params.viewingArchives)
            IconButton(
              icon: const Icon(SpIcons.archive),
              onPressed: () => viewModel.goToArchivesPage(context),
            ),
        ],
      ),
      floatingActionButton: viewModel.params.viewingArchives ? null : buildFAB(context),
      body: buildBody(context),
    );
  }

  Widget buildFAB(BuildContext context) {
    if (!MediaQuery.accessibleNavigationOf(context)) {
      return FloatingActionButton.extended(
        tooltip: tr('button.new_template'),
        elevation: 0.0,
        backgroundColor: ColorScheme.of(context).secondary,
        foregroundColor: ColorScheme.of(context).onSecondary,
        heroTag: null,
        onPressed: () => viewModel.goToNewPage(context),
        label: Text(tr('button.new_template')),
        icon: const Icon(SpIcons.add),
        shape: const StadiumBorder(),
      );
    } else {
      return FloatingActionButton(
        tooltip: tr('button.new_template'),
        elevation: 0.0,
        backgroundColor: ColorScheme.of(context).secondary,
        foregroundColor: ColorScheme.of(context).onSecondary,
        heroTag: null,
        child: const Icon(SpIcons.add),
        onPressed: () => viewModel.goToNewPage(context),
      );
    }
  }

  Widget buildBody(BuildContext context) {
    final templates = viewModel.templates?.items;

    if (templates == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (templates.isEmpty == true) {
      return const _EmptyBody();
    }

    return ReorderableListView.builder(
      itemCount: templates.length,
      padding: EdgeInsets.only(
        top: 8.0,
        left: MediaQuery.of(context).padding.left + 10.0,
        right: MediaQuery.of(context).padding.right + 10.0,
        bottom: MediaQuery.of(context).padding.bottom + kToolbarHeight + 24.0,
      ),
      onReorder: (int oldIndex, int newIndex) => viewModel.reorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        return Container(
          key: ValueKey(templates[index].id),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6.0),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).readOnly.surface1,
            borderRadius: BorderRadiusGeometry.circular(8.0),
          ),
          child: _TemplateTile(
            viewModel: viewModel,
            template: templates[index],
          ),
        );
      },
    );
  }
}
