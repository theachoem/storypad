import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/views/languages/languages_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
    required this.weekday,
  });

  final int weekday;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => LanguagesRoute().push(context),
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.globe),
      subtitle: Text(kNativeLanguageNames[context.locale.toLanguageTag()]!),
      title: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          text: "${tr("page.language.title")} ",
          children: [
            // WidgetSpan(
            //   child: Material(
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
            //     color: ColorScheme.of(context).bootstrap.success.color,
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(
            //         horizontal: MediaQuery.textScalerOf(context).scale(6),
            //         vertical: MediaQuery.textScalerOf(context).scale(1),
            //       ),
            //       child: Text(
            //         tr('general.beta'),
            //         style: TextTheme.of(context)
            //             .labelMedium
            //             ?.copyWith(color: ColorScheme.of(context).bootstrap.success.onColor),
            //       ),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
