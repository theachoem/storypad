part of 'library_view.dart';

class _LibraryContent extends StatelessWidget {
  const _LibraryContent(
    this.viewModel, {
    required this.constraints,
  });

  final LibraryViewModel viewModel;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: viewModel.params.initialTabIndex,
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(tr("page.library.title_with_app_name")),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(SpIcons.photo)),
                  Tab(icon: Icon(SpIcons.voice)),
                ],
              ),
            ),
            body: buildBody(context),
          );
        },
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return TabBarView(
      children: [
        _ImagesTabContent(constraints: constraints),
        _VoicesTabContent(constraints: constraints),
      ],
    );
  }
}
