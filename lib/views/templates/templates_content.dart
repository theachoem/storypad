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
            IconButton(
              icon: const Icon(SpIcons.lightBulb),
              onPressed: () => viewModel.goToNewPage(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          elevation: 0.0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.primary,
          isExtended: true,
          shape: StadiumBorder(side: BorderSide(color: Theme.of(context).dividerColor)),
          label: const Text("New Template"),
          icon: const Icon(SpIcons.add),
          onPressed: () => viewModel.goToNewPage(context),
        ),
        body: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.templates == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (viewModel.templates!.isEmpty == true) {
      return const _EmptyBody();
    }

    return ListView.separated(
      itemCount: viewModel.templates!.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _TemplateTile(
          viewModel: viewModel,
          template: viewModel.templates![index],
        );
      },
    );
  }
}
