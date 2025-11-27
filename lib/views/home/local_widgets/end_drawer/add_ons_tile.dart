part of 'home_end_drawer.dart';

class _AddOnsTile extends StatelessWidget {
  const _AddOnsTile();

  @override
  Widget build(BuildContext context) {
    return SpNewBadgeBuilder(
      badgeKey: NewBadge.add_on_tile_with_period_calendar.name,
      builder: (context, newBadge, hideBadge) {
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
          leading: const Icon(SpIcons.addOns),
          trailing: context.read<InAppPurchaseProvider>().hasActiveDeals ? const SpGiftAnimatedIcon() : null,
          title: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              text: "${tr('page.add_ons.title')} ",
              children: [
                if (newBadge != null) WidgetSpan(child: newBadge),
              ],
            ),
          ),
          onTap: () async {
            await const AddOnsRoute().push(context);
            hideBadge();
          },
        );
      },
    );
  }
}
