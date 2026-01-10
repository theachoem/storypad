import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/types/new_badge.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_new_badge_builder.dart';

class AddOnsTile extends StatelessWidget {
  const AddOnsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpNewBadgeBuilder(
      badgeKey: NewBadge.add_on_tile_with_period_calendar.name,
      builder: (context, newBadge, hideBadge) {
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
          leading: const Icon(SpIcons.addOns),
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
