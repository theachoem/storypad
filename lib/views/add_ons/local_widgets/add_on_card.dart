part of '../add_ons_view.dart';

class _AddOnGridItem extends StatelessWidget {
  const _AddOnGridItem({
    required this.addOn,
    required this.onTap,
  });

  final AddOnObject addOn;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);
    final backgroundColor =
        ColorFromDayService(context: context).get(addOn.weekdayColor) ?? ColorScheme.of(context).primary;
    final isActive = iapProvider.isActive(addOn.type.productIdentifier);

    return Material(
      color: ColorScheme.of(context).surface,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildIconHeader(context, backgroundColor, isActive),
            buildContent(context, isActive),
          ],
        ),
      ),
    );
  }

  Widget buildIconHeader(BuildContext context, Color backgroundColor, bool isActive) {
    return Container(
      color: backgroundColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(12.0),
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Icon(
        addOn.iconData,
        size: 32.0,
        color: backgroundColor,
      ),
    );
  }

  Widget buildContent(BuildContext context, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              text: addOn.title,
              children: [
                if (addOn.designForFemale) ...[
                  const TextSpan(text: ' '),
                  const WidgetSpan(
                    child: Icon(Icons.female_outlined, size: 16.0),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ],
            ),
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          Stack(
            children: [
              // reserved 2 line.
              Text("\n\n", style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
              Text(
                addOn.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorScheme.of(context).onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          buildFooter(context, isActive),
        ],
      ),
    );
  }

  Widget buildFooter(BuildContext context, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isActive)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: ColorScheme.of(context).primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(
                SpIcons.verifiedFilled,
                size: 18.0,
                color: ColorScheme.of(context).primary,
              ),
            ),
          ),
        if (addOn.displayPrice != null)
          Flexible(
            child: Text(
              addOn.displayPrice!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ColorScheme.of(context).primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }
}
