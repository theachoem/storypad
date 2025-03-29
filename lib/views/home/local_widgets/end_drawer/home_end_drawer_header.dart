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
        child: Column(
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
                text: tr("button.switch"),
                style: TextTheme.of(context).labelLarge,
                children: const [
                  WidgetSpan(
                    child: Icon(Icons.keyboard_arrow_down_outlined, size: 16.0),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
