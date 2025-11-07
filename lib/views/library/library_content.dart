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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("page.library.title_with_app_name")),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(SpIcons.photo)),
              Tab(icon: Icon(SpIcons.voice)),
            ],
          ),
        ),
        body: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ImageTabContent(constraints: constraints),
        _VoicesTabContent(constraints: constraints),
      ],
    );
  }
}
