import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

class FontWeightTile extends StatelessWidget {
  const FontWeightTile({
    super.key,
    required this.currentFontWeight,
    required this.onChanged,
  });

  final FontWeight currentFontWeight;
  final void Function(FontWeight value) onChanged;

  static Widget globalTheme() {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return FontWeightTile(
          currentFontWeight: provider.theme.fontWeight,
          onChanged: (FontWeight fontWeight) => provider.setFontWeight(fontWeight),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpPopupMenuButton(
      smartDx: true,
      dyGetter: (dy) => dy + 44.0,
      items: (context) => FontWeight.values.map((fontWeight) {
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

        return SpPopMenuItem(
          selected: fontWeight == currentFontWeight,
          title: "${fontWeight.value} - ${descriptions[fontWeight.value]}",
          onPressed: () => onChanged(fontWeight),
        );
      }).toList(),
      builder: (open) {
        return ListTile(
          leading: const Icon(SpIcons.fontWeight),
          title: Text(tr("list_tile.font_weight.title")),
          subtitle: Text(currentFontWeight.value.toString()),
          onTap: () => open(),
        );
      },
    );
  }
}
