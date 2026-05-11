import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_font_weight_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class FontWeightTile extends StatelessWidget {
  const FontWeightTile({
    super.key,
    required this.weekday,
    required this.currentFontWeight,
    required this.onChanged,
    this.locked = false,
  });

  final int weekday;
  final FontWeight currentFontWeight;
  final void Function(FontWeight value) onChanged;
  final bool locked;

  static Widget globalTheme({required int weekday}) {
    return Consumer2<DevicePreferencesProvider, InAppPurchaseProvider>(
      builder: (context, provider, inAppPurchaseProvider, child) {
        return FontWeightTile(
          weekday: weekday,
          currentFontWeight: provider.preferences.fontWeight,
          onChanged: (FontWeight fontWeight) => provider.setFontWeight(fontWeight),
          locked: !inAppPurchaseProvider.isProUser,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.fontWeight),
      title: Text(tr("list_tile.font_weight.title")),
      subtitle: Text(getFontWeightTitle(currentFontWeight)),
      trailing: locked ? const Icon(SpIcons.lock) : null,
      onTap: () {
        SpFontWeightSheet(
          fontWeight: currentFontWeight,
          onChanged: onChanged,
          locked: locked,
        ).show(context: context);
      },
    );
  }

  static String getFontWeightTitle(FontWeight fontWeight) {
    final descriptions = {
      100: tr("general.font_weight.thin"),
      200: tr("general.font_weight.extra_light"),
      300: tr("general.font_weight.light"),
      400: tr("general.font_weight.normal"),
      500: tr("general.font_weight.medium"),
      600: tr("general.font_weight.semi_bold"),
      700: tr("general.font_weight.bold"),
      800: tr("general.font_weight.extra_bold"),
      900: tr("general.font_weight.black"),
    };

    return "${fontWeight.value} - ${descriptions[fontWeight.value]}";
  }
}
