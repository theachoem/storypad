import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/fonts/fonts_view.dart';

class FontFamilyTile extends StatelessWidget {
  const FontFamilyTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeProvider provider = Provider.of<ThemeProvider>(context);
    return ListTile(
      leading: const Icon(Icons.font_download_outlined),
      title: Text(tr("list_tile.font_family.title")),
      subtitle: Text(provider.theme.fontFamily),
      onTap: () {
        FontsRoute().push(context);
      },
    );
  }
}
