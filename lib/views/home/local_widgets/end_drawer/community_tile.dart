part of 'home_end_drawer.dart';

class _CommunityTile extends StatelessWidget {
  const _CommunityTile();

  @override
  Widget build(BuildContext context) {
    return SpNewBadgeBuilder(
      badge: NewBadge.community_tile_with_donation,
      builder: (context, newBadge, hideBadge) {
        return ListTile(
          leading: const Icon(SpIcons.forum),
          title: RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              text: "${tr("page.community.title")} ",
              children: [
                if (newBadge != null) WidgetSpan(child: newBadge),
              ],
            ),
          ),
          onTap: () async {
            await CommunityRoute().push(context);
            hideBadge();
          },
        );
      },
    );
  }
}
