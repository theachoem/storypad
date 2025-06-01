part of 'templates_view.dart';

class _TemplatesContent extends StatelessWidget {
  const _TemplatesContent(this.viewModel);

  final TemplatesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          title: Text(tr("page.templates.title")),
          actions: [
            // IconButton(
            //   icon: const Icon(SpIcons.lightBulb),
            //   onPressed: () => viewModel.goToNewPage(context),
            // ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          elevation: 0.0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.primary,
          isExtended: true,
          shape: StadiumBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
          label: Text(tr('button.new_template')),
          icon: const Icon(SpIcons.add),
          onPressed: () => viewModel.goToNewPage(context),
        ),
        body: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    final templates = viewModel.templates?.items;

    if (templates == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (templates.isEmpty == true) {
      return const _EmptyBody();
    }

    return ReorderableListView.builder(
      itemCount: templates.length,
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16.0),
      onReorder: (int oldIndex, int newIndex) => viewModel.reorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        return Container(
          key: ValueKey(templates[index].id),
          margin: EdgeInsets.only(bottom: index == templates.length - 1 ? 0 : 8.0),
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
