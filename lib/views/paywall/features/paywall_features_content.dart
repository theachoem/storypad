part of 'paywall_features_view.dart';

class _PaywallFeaturesContent extends StatelessWidget {
  const _PaywallFeaturesContent(this.viewModel);

  final PaywallFeaturesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);
    final activeDeal = iapProvider.getActiveDeal(.storypad_pro_lifetime);

    return Scaffold(
      appBar: CupertinoSheetRoute.hasParentSheet(context)
          ? AppBar(
              automaticallyImplyLeading: false,
              actions: [
                CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
              ],
            )
          : null,
      floatingActionButtonLocation: .centerFloat,
      bottomNavigationBar: activeDeal.displayPrice == null
          ? null
          : SpFadeIn.fromBottom(
              duration: Durations.long1,
              child: Column(
                mainAxisSize: .min,
                children: [
                  if (activeDeal.badgeLabel != null || activeDeal.displayComparePrice != null) ...[
                    if (activeDeal.badgeLabel != null) ...[
                      Text(
                        activeDeal.badgeLabel!,
                        style: TextTheme.of(context).bodyMedium,
                      ),
                    ],
                    if (activeDeal.displayComparePrice != null) ...[
                      Text(
                        "${activeDeal.displayComparePrice}",
                        style: TextTheme.of(context).bodyLarge?.copyWith(
                          color: ColorScheme.of(context).error,
                          fontWeight: .bold,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: ColorScheme.of(context).error,
                        ),
                        textAlign: .start,
                      ),
                    ],
                    const SizedBox(height: 8.0),
                  ],
                  if (!iapProvider.isProUser) ...[
                    FloatingActionButton.extended(
                      heroTag: null,
                      backgroundColor: ColorScheme.of(context).primary,
                      foregroundColor: ColorScheme.of(context).onPrimary,
                      shape: const StadiumBorder(),
                      label: Text(
                        tr(
                          'button.purchase_for_args',
                          namedArgs: {
                            'PRICE': activeDeal.displayPrice ?? 'N/A',
                          },
                        ),
                      ),
                      icon: const Icon(SpIcons.star),
                      onPressed: () => iapProvider.purchase(context),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                  SpPageIndicator(
                    controller: viewModel.pageController,
                    pageCount: viewModel.params.features.length,
                    maxVisiblePages: 4,
                    activeColor: ColorScheme.of(context).primary,
                    inactiveColor: ColorScheme.of(context).primary.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
      body: SpPageView(
        controller: viewModel.pageController,
        itemCount: viewModel.params.features.length,
        itemBuilder: (context, index) {
          final feature = viewModel.params.features[index];

          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _Page(
              viewModel: viewModel,
              feature: feature,
              topPadding: CupertinoSheetRoute.hasParentSheet(context) ? 0.0 : 8.0,
            ),
          );
        },
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.viewModel,
    required this.feature,
    required this.topPadding,
  });

  final PaywallFeaturesViewModel viewModel;
  final PaywallFeatureObject feature;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

    return ListView(
      controller: PrimaryScrollController.of(context),
      children: [
        SizedBox(height: topPadding),
        Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
          child: buildHeaderContents(context, iapProvider),
        ),
        const SizedBox(height: 16.0),
        Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
          child: SpDemoImages(
            demoImageUrlPaths: feature.demoImagePaths,
            skeletonCount: feature.demoImagePaths.length,
          ),
        ),
      ],
    );
  }

  Widget buildHeaderContents(BuildContext context, InAppPurchaseProvider iapProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: ColorFromDayService(context: context).get(feature.weekdayColor),
            foregroundColor: ColorScheme.of(context).onPrimary,
            child: Icon(feature.iconData),
          ),
          const SizedBox(height: 12.0),
          Text.rich(
            style: TextTheme.of(context).titleLarge,
            textAlign: TextAlign.center,
            TextSpan(
              text: feature.title,
              children: [
                if (feature.designForFemale)
                  const WidgetSpan(
                    child: Icon(Icons.female_outlined, size: 22.0),
                    alignment: PlaceholderAlignment.middle,
                  ),
              ],
            ),
          ),
          Text(
            feature.subtitle,
            style: TextTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (iapProvider.isProUser && feature.onOpen != null) ...[
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                child: Text(tr('button.open')),
                onPressed: () {
                  Navigator.maybePop(
                    context,
                    PaywallFeatureNextAction(
                      focusFeature: feature,
                      action: (BuildContext context) => feature.onOpen!(context),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
