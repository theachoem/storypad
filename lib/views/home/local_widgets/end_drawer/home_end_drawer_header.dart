part of 'home_end_drawer.dart';

class _HomeEndDrawerHeader extends StatelessWidget {
  const _HomeEndDrawerHeader(this.viewModel);

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => HomeYearsRoute(viewModel: viewModel).push(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: [
                Text(
                  viewModel.year.toString(),
                  style: TextTheme.of(context).displayMedium?.copyWith(color: ColorScheme.of(context).primary),
                ),
                RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    text: "${tr("button.switch")} ",
                    style: TextTheme.of(context).labelLarge,
                    children: const [
                      WidgetSpan(
                        child: Icon(SpIcons.keyboardDown, size: 16.0),
                        alignment: PlaceholderAlignment.middle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SpFadeIn.fromRight(
                delay: const Duration(milliseconds: 200),
                child: IconButton.filledTonal(
                  color: ColorScheme.of(context).primary,
                  icon: const Icon(SpIcons.starFilled),
                  onPressed: () => const PaywallsRoute().push(context, rootNavigator: true),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
