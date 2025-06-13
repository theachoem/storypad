part of '../paywalls_view.dart';

class _Offers extends StatelessWidget {
  const _Offers({
    required this.viewModel,
  });

  final PaywallsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final offers = viewModel.offers;
    if (offers == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            border: Border.all(
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                return Container(
                  width: double.infinity,
                  color: Colors.red,
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < offers.length; i++)
                        buildOffer(
                          i,
                          context,
                          constraints.maxWidth / 3 - 16 * 2 / 3 - 6 / 3,
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16.0),
              buildGuideText(offers),
              const SizedBox(height: 16.0),
              buildMainButton(context),
              SizedBox(height: MediaQuery.of(context).padding.bottom)
            ],
          ),
        ),
      ],
    );
  }

  Widget buildGuideText(List<PaywallsOffering> offers) {
    return IndexedStack(
      index: viewModel.selectedOfferIndex,
      children: [
        for (int i = 0; i < offers.length; i++)
          Row(
            spacing: 8.0,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(SpIcons.lightBulb),
              Expanded(
                child: Text(
                  offers[i].helperText,
                  maxLines: 3,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget buildMainButton(BuildContext context) {
    final offers = viewModel.offers;
    if (offers == null) return const SizedBox.shrink();
    final offer = offers[viewModel.selectedOfferIndex];

    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(8),
          ),
        ),
        child: RichText(
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(
            text: offer.interested ? "Interested " : "I'm intereted in ${offer.name.toLowerCase()} plan ",
            style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).onPrimary),
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  offer.interested ? Icons.favorite : Icons.favorite_outline,
                  color: ColorScheme.of(context).onPrimary,
                  size: MediaQuery.textScalerOf(context).scale(14.0),
                ),
              ),
            ],
          ),
        ),
        onPressed: () => viewModel.markAsInterested(),
      ),
    );
  }

  Widget buildOffer(
    int i,
    BuildContext context,
    double width,
  ) {
    final offers = viewModel.offers;
    if (offers == null) return const SizedBox.shrink();

    final offer = offers[i];

    return SpTapEffect(
      effects: [SpTapEffectType.scaleDown],
      onTap: () => viewModel.setSelectOfferIndex(i),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            width: width,
            curve: Curves.ease,
            duration: Durations.medium1,
            padding: EdgeInsets.only(left: 8.0, right: 8.0, top: offer.badge != null ? 24.0 : 16.0, bottom: 16.0),
            margin: EdgeInsets.only(right: i == 2 ? 0 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadiusGeometry.circular(8),
              border: Border.all(
                width: viewModel.selectedOfferIndex == i ? 3 : 1,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: viewModel.selectedOfferIndex == i
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Column(
              children: [
                Text(
                  offer.name,
                  textAlign: TextAlign.center,
                  style: TextTheme.of(context).bodyMedium,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6.0,
                  children: [
                    if (offer.compareAtPrice != null)
                      Text(
                        offer.compareAtPrice!,
                        textAlign: TextAlign.center,
                        style: TextTheme.of(context).bodyLarge?.copyWith(decoration: TextDecoration.lineThrough),
                      ),
                    Text(
                      offer.baseDisplayPrice,
                      textAlign: TextAlign.center,
                      style: TextTheme.of(context).headlineSmall?.copyWith(
                          fontWeight: viewModel.selectedOfferIndex == i ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (offer.badge != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                transform: Matrix4.identity()..translate(0.0, -8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: ColorScheme.of(context).primary,
                ),
                child: Text(
                  offer.badge!,
                  style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).onPrimary),
                ),
              ),
            )
        ],
      ),
    );
  }
}
