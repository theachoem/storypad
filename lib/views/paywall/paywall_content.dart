part of 'paywall_view.dart';

class _PaywallContent extends StatelessWidget {
  const _PaywallContent(this.viewModel);

  final PaywallViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: false,
        scrolledUnderElevation: 3.0,
      ),
      body: buildBody(context, iapProvider),
      floatingActionButtonLocation: .centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        shape: const StadiumBorder(),
        label: Text(tr('button.purchase_for_args', namedArgs: {'PRICE': '\$4.99'})),
        icon: const Icon(SpIcons.star),
        onPressed: () => iapProvider.purchase(context, AppProduct.pro.productIdentifier, null),
      ),
    );
  }

  Widget buildTermPrivacyRestorePurchaseTexts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 8.0,
        bottom: 16.0,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children:
            [
              (
                (tr('general.term_of_use')),
                () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/term-of-use'),
              ),
              (
                (tr('general.privacy_policy')),
                () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/privacy-policy'),
              ),
              ("•", null),
              (
                tr('button.restore_purchase'),
                () => context.read<InAppPurchaseProvider>().restorePurchase(context),
              ),
              (
                tr('button.redeem_code'),
                () {
                  if (Platform.isIOS) {
                    context.read<InAppPurchaseProvider>().presentCodeRedemptionSheet(context);
                  } else if (Platform.isAndroid) {
                    SpAndroidRedemptionSheet().show(context: context);
                  }
                },
              ),
            ].map((link) {
              return SpTapEffect(
                onTap: link.$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
                  child: Text(
                    link.$1,
                    style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).primary),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget buildBody(BuildContext context, InAppPurchaseProvider iapProvider) {
    final features = viewModel.features;

    if (features == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return Stack(
      children: [
        ListView(
          padding: EdgeInsetsGeometry.only(
            bottom: MediaQuery.paddingOf(context).bottom + kToolbarHeight + 96.0,
          ),
          children: [
            const _PaywallHeader(),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            for (int i = 0; i < features.length; i++) ...[
              _FeatureTile(
                key: viewModel.featureKeys[i],
                viewModel: viewModel,
                feature: features[i],
              ),
            ],
            const SizedBox(height: 20.0),
            const Divider(height: 1),
            const SizedBox(height: 16.0),
            buildTermPrivacyRestorePurchaseTexts(context),
          ],
        ),
        buildGradientBgOverlay(context),
      ],
    );
  }

  Widget buildGradientBgOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: kToolbarHeight + 32.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: .topCenter,
            end: .bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
      ),
    );
  }
}
