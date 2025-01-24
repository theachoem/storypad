part of '../home_view.dart';

class _HomeEndDrawerHeader extends StatelessWidget {
  const _HomeEndDrawerHeader();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeViewModel>(context);

    return InkWell(
      onTap: () => SpNestedNavigation.maybeOf(context)?.push(const HomeYearsView()),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4.0,
          children: [
            Text(
              provider.year.toString(),
              style: TextTheme.of(context).displayMedium?.copyWith(color: ColorScheme.of(context).primary),
            ),
            RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                text: "Switch",
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
