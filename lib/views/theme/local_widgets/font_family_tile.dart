import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/fonts/fonts_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_fonts_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class FontFamilyTile extends StatelessWidget {
  const FontFamilyTile({
    super.key,
    required this.currentFontFamily,
    required this.currentFontWeight,
    required this.onChanged,
    required this.showSheet,
  });

  final String currentFontFamily;
  final FontWeight currentFontWeight;
  final bool showSheet;
  final void Function(String fontFamily) onChanged;

  static Widget globalTheme() {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return FontFamilyTile(
          showSheet: false,
          currentFontWeight: provider.theme.fontWeight,
          currentFontFamily: provider.theme.fontFamily,
          onChanged: (fontFamily) => provider.setFontFamily(fontFamily),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.font),
      title: Text(tr("list_tile.font_family.title")),
      subtitle: Text(currentFontFamily),
      onTap: () {
        if (showSheet) {
          SpFontsSheet(
            currentFontFamily: currentFontFamily,
            currentFontWeight: currentFontWeight,
            onChanged: onChanged,
          ).show(context: context);
        } else {
          FontsRoute(
            currentFontFamily: currentFontFamily,
            currentFontWeight: currentFontWeight,
            onChanged: onChanged,
          ).push(context);
        }
      },
    );
  }
}
