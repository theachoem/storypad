import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/new_badge.dart';
import 'package:storypad/views/community/community_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_new_badge_builder.dart';

class CommunityTile extends StatelessWidget {
  const CommunityTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpNewBadgeBuilder(
      badgeKey: NewBadge.none.name,
      builder: (context, newBadge, hideBadge) {
        return ListTile(
          leading: const Icon(SpIcons.forum),
          title: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              text: "${tr("page.community.title")} ",
              children: [
                if (newBadge != null) WidgetSpan(child: newBadge),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
          onTap: () async {
            await CommunityRoute().push(context);
            hideBadge();
          },
        );
      },
    );
  }
}
