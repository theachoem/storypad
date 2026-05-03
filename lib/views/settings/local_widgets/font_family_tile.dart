import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_fonts_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class FontFamilyTile extends StatelessWidget {
  const FontFamilyTile({
    super.key,
    required this.weekday,
    required this.currentFontFamily,
    required this.currentFontWeight,
    required this.onChanged,
  });

  final int weekday;

  final String currentFontFamily;
  final FontWeight currentFontWeight;
  final void Function(String fontFamily) onChanged;

  static Widget globalTheme({required int weekday}) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return FontFamilyTile(
          weekday: weekday,
          currentFontWeight: provider.preferences.fontWeight,
          currentFontFamily: provider.preferences.fontFamily,
          onChanged: (fontFamily) => provider.setFontFamily(fontFamily),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.font),
      title: Text(tr("list_tile.font_family.title")),
      subtitle: Text(currentFontFamily),
      onTap: () {
        SpFontsSheet(
          currentFontFamily: currentFontFamily,
          currentFontWeight: currentFontWeight,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }
}
