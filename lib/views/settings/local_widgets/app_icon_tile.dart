import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/bottom_sheets/sp_nickname_bottom_sheet.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpSingleStateWidget.listen(
      initialValue: DateTime.now(),
      builder: (context, rebuildAt, notifier) {
        return ListTile(
          title: Text(tr('general.app_icon')),
          leading: Transform.scale(
            scale: 1.3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorScheme.of(context).readOnly.surface2,
              ),
              child: Transform.scale(
                scale: 1.15,
                child: kAppLogo!.asset.image(width: 24, height: 24),
              ),
            ),
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
