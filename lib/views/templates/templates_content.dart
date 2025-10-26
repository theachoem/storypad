part of 'templates_view.dart';

class _TemplatesContent extends StatelessWidget {
  const _TemplatesContent(this.viewModel);

  final TemplatesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.params.viewingArchives) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('general.path_type.archives')),
        ),
        body: TemplatesTab(
          params: viewModel.params,
          appBarActionsLoaderCallback: null,
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: buildAppBar(context),
            body: buildBody(context),
          );
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        viewModel.params.viewingArchives ? tr('general.path_type.archives') : tr("add_ons.templates.title"),
      ),
      actions: [
        if (!viewModel.params.viewingArchives) buildActions(),
      ],
      bottom: TabBar(
        onTap: (index) {
          if (index == 1 && !context.read<InAppPurchaseProvider>().template) {
            DefaultTabController.of(context).animateTo(0);
            AddOnsRoute.pushAndNavigateTo(
              product: AppProduct.templates,
              context: context,
              fullscreenDialog: true,
            );
          }
        },
        tabs: [
          Tab(text: tr('general.gallery')),
          Tab(
            child: Consumer<InAppPurchaseProvider>(
              builder: (context, iapProvider, child) {
                return Text.rich(
                  TextSpan(
                    text: "${tr('general.my_templates')} ",
                    children: [
                      if (!iapProvider.template)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            SpIcons.lock,
                            size: 16.0,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActions() {
    return ValueListenableBuilder(
      valueListenable: viewModel.appBarActionsNotifier,
      builder: (context, appBarActions, child) {
        return Row(
          children: appBarActions?.map((child) => SpFadeIn.bound(child: child)).toList() ?? [],
        );
      },
    );
  }

  Widget buildBody(BuildContext context) {
    return TabBarView(
      children: [
        GalleryTab(
          params: viewModel.params,
          appBarActionsLoaderCallback: (List<IconButton> icons) {
            viewModel.appBarActionsNotifier.value = icons;
          },
        ),
        TemplatesTab(
          params: viewModel.params,
          appBarActionsLoaderCallback: (List<IconButton> icons) {
            viewModel.appBarActionsNotifier.value = icons;
          },
        ),
      ],
    );
  }
}
