part of 'templates_view.dart';

class _TemplatesContent extends StatelessWidget {
  const _TemplatesContent(this.viewModel);

  final TemplatesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("add_ons.templates.title")),
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: tr('button.new_template'),
        elevation: 0.0,
        backgroundColor: ColorScheme.of(context).secondary,
        foregroundColor: ColorScheme.of(context).onSecondary,
        heroTag: null,
        child: const Icon(SpIcons.add),
        onPressed: () => viewModel.goToNewPage(context),
      ),
      body: buildBody(context),
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
      padding: EdgeInsets.only(
        top: 16.0,
        left: MediaQuery.of(context).padding.left + 16.0,
        right: MediaQuery.of(context).padding.right + 16.0,
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
      ),
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
