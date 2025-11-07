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
              bottom: TabBar(
                onTap: (index) {
                  if (index == 1 && !context.read<InAppPurchaseProvider>().voiceJournal) {
                    DefaultTabController.of(context).animateTo(0);
                    AddOnsRoute.pushAndNavigateTo(
                      product: AppProduct.voice_journal,
                      context: context,
                      fullscreenDialog: true,
                    );
                  }
                },
                tabs: [
                  const Tab(icon: Icon(SpIcons.photo)),
                  Tab(
                    icon: Consumer<InAppPurchaseProvider>(
                      builder: (context, provider, child) {
                        return provider.voiceJournal
                            ? const Icon(SpIcons.voice)
                            : const Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(SpIcons.voice),
                                  Positioned(
                                    top: 0,
                                    right: -8,
                                    child: Icon(SpIcons.lock, size: 12.0),
                                  ),
                                ],
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
            body: buildBody(),
          );
        },
      ),
    );
  }

  Widget buildBody() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ImagesTabContent(constraints: constraints),
        _VoicesTabContent(constraints: constraints),
      ],
    );
  }
}
