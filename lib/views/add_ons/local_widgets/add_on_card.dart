part of '../add_ons_view.dart';

class _AddOnCard extends StatelessWidget {
  const _AddOnCard({
    required this.addOn,
    required this.onTap,
  });

  final AddOnObject addOn;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

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
          children: [
            buildTextContents(context),
            buildActionAndPrice(context, iapProvider),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  Widget buildTextContents(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      contentPadding: const EdgeInsets.only(left: 12.0, right: 14.0, top: 8.0),
      trailing: CircleAvatar(
        backgroundColor: ColorFromDayService(context: context).get(addOn.weekdayColor),
        foregroundColor: ColorScheme.of(context).onPrimary,
        child: Icon(addOn.iconData),
      ),
      title: Text.rich(
        TextSpan(
          text: addOn.title,
          children: [
            if (addOn.designForFemale)
              const WidgetSpan(
                child: Icon(Icons.female_outlined, size: 20.0),
                alignment: PlaceholderAlignment.middle,
              ),
          ],
        ),
      ),
      subtitle: Text(addOn.subtitle),
    );
  }

  Widget buildActionAndPrice(BuildContext context, InAppPurchaseProvider iapProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: Row(
        children: [
          if (iapProvider.isActive(addOn.type.productIdentifier))
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(SpIcons.verifiedFilled),
              label: Text(tr('button.view')),
            )
          else
            OutlinedButton(
              onPressed: onTap,
              child: Text(tr('button.view')),
            ),
          if (addOn.displayPrice != null)
            Expanded(
              child: Text(
                addOn.displayPrice!,
                style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
