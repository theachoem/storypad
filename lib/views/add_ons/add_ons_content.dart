part of 'add_ons_view.dart';

class _AddOnsContent extends StatelessWidget {
  const _AddOnsContent(this.viewModel);

  final AddOnsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.add_ons.title')),
        centerTitle: kIsCupertino,
      ),
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigation(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.addOns == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16.0),
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      itemCount: viewModel.addOns!.length,
      itemBuilder: (context, index) {
        final addOn = viewModel.addOns![index];

        return _AddOnCard(
          addOn: addOn,
          onTap: () => ShowAddOnRoute(addOn: addOn).push(context),
        );
      },
    );
  }

  Widget buildBottomNavigation(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: MediaQuery.of(context).padding.bottom + 16.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: [
          (
            tr('general.term_of_use'),
            () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/term-of-use'),
          ),
          (
            tr('general.privacy_policy'),
            () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/privacy-policy')
          ),
          (
            tr('button.restore_purchase'),
            () => viewModel.restorePurchase(context),
          ),
        ].map((link) {
          return SpTapEffect(
            onTap: link.$2,
            child: Container(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                link.$1,
                style: TextTheme.of(context).bodyMedium?.copyWith(
                      color: ColorScheme.of(context).primary,
                      decoration: TextDecoration.underline,
                      decorationColor: ColorScheme.of(context).primary,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
