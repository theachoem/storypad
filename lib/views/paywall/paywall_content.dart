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
        actions: [
          const _PurchaseSyncAvatarButton(),
        ],
      ),
      body: buildBody(context, iapProvider),
      bottomNavigationBar: iapProvider.getActiveDeal(.storypad_pro_lifetime).displayPrice == null
          ? null
          : SpFadeIn.fromBottom(
              duration: Durations.long1,
              child: Column(
                mainAxisSize: .min,
                spacing: 8.0,
                children: [
                  if (!iapProvider.isProUser)
                    FloatingActionButton.extended(
                      heroTag: null,
                      backgroundColor: ColorScheme.of(context).primary,
                      foregroundColor: ColorScheme.of(context).onPrimary,
                      shape: const StadiumBorder(),
                      label: Text(
                        tr(
                          'button.purchase_for_args',
                          namedArgs: {'PRICE': iapProvider.getActiveDeal(.storypad_pro_lifetime).displayPrice ?? 'N/A'},
                        ),
                      ),
                      icon: const Icon(SpIcons.star),
                      onPressed: () => iapProvider.purchase(context),
                    ),
                  const _RestoreAndRedeemTexts(),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
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
          padding: const EdgeInsetsGeometry.only(bottom: 96.0),
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
            ListTile(
              leading: const SpSettingIconBadge(weekday: 2, icon: SpIcons.star),
              title: Text(tr('list_tile.support_indie_dev.title')),
              subtitle: Text(tr('list_tile.support_indie_dev.subtitle')),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0).add(
                EdgeInsets.only(
                  left: MediaQuery.of(context).padding.left,
                  right: MediaQuery.of(context).padding.right,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 1),
            const SizedBox(height: 8.0),
            const _TermPrivacyTexts(),
          ],
        ),
        const _PaywallGradientBgOverlay(),
      ],
    );
  }
}
