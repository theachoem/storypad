part of 'home_end_drawer.dart';

class _AddOnsTile extends StatelessWidget {
  const _AddOnsTile();

  @override
  Widget build(BuildContext context) {
    return SpNewBadgeBuilder(
      badge: NewBadge.add_on_tile_with_reward,
      builder: (context, newBadge, hideBadge) {
        return ListTile(
          leading: const Icon(SpIcons.addOns),
          title: RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
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
