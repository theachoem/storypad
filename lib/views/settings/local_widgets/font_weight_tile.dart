import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_font_weight_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class FontWeightTile extends StatelessWidget {
  const FontWeightTile({
    super.key,
    required this.currentFontWeight,
    required this.onChanged,
  });

  final FontWeight currentFontWeight;
  final void Function(FontWeight value) onChanged;

  static Widget globalTheme() {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return FontWeightTile(
          currentFontWeight: provider.preferences.fontWeight,
          onChanged: (FontWeight fontWeight) => provider.setFontWeight(fontWeight),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.fontWeight),
      title: Text(tr("list_tile.font_weight.title")),
      subtitle: Text(getFontWeightTitle(currentFontWeight)),
      onTap: () {
        SpFontWeightSheet(
          fontWeight: currentFontWeight,
          onChanged: onChanged,
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
