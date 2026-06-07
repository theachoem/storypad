import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/home_quick_actions/home_quick_actions_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class QuickActionsTile extends StatelessWidget {
  // Ignore const so changing locale work.
  // ignore: prefer_const_constructors_in_immutables
  QuickActionsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inAppPurchaseProvider = Provider.of<InAppPurchaseProvider>(context);
    final locked = !inAppPurchaseProvider.isProUser;

    return ListTile(
      trailing: locked ? const Icon(SpIcons.lock) : null,
      leading: const SpSettingIconBadge(weekday: 1, icon: SpIcons.home),
      title: Text(tr('page.home_quick_actions.title')),
      onTap: () => const HomeQuickActionsRoute().push(context),
    );
  }
}
