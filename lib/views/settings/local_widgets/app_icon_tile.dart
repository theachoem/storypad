import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_nickname_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inAppPurchaseProvider = Provider.of<InAppPurchaseProvider>(context);
    final locked = !inAppPurchaseProvider.isProUser;

    return SpSingleStateWidget.listen(
      initialValue: DateTime.now(),
      builder: (context, rebuildAt, notifier) {
        return ListTile(
          title: Text(tr('general.app_icon')),
          trailing: locked ? const Icon(SpIcons.lock) : null,
          leading: Container(
            width: 40,
            height: 40,
            clipBehavior: .hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: kAppLogo!.asset.image(width: 32, height: 32, fit: BoxFit.cover),
          ),
          onTap: () async {
            await SpNicknameBottomSheet(
              nickname: PreferenceDbModel.db.nickname.get(),
              showLogoSelectorOnly: true,
            ).show(context: context);

            notifier.value = DateTime.now();
          },
        );
      },
    );
  }
}
