import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeProvider provider = Provider.of<ThemeProvider>(context);

    return SpPopupMenuButton(
      smartDx: true,
      dyGetter: (dy) => dy + 44.0,
      items: (context) => ThemeMode.values.map((mode) {
        return SpPopMenuItem(
          selected: mode == provider.themeMode,
          title: getLocalizedThemeMode(mode),
          onPressed: () => provider.setThemeMode(mode),
        );
      }).toList(),
      builder: (open) {
        return ListTile(
          leading: SpAnimatedIcons(
            duration: Durations.medium4,
            firstChild: const Icon(Icons.dark_mode),
            secondChild: const Icon(Icons.light_mode),
            showFirst: provider.isDarkMode(context),
          ),
          title: Text(tr('list_tile.theme_mode.title')),
          subtitle: Text(getLocalizedThemeMode(provider.themeMode)),
          onTap: () => open(),
        );
      },
    );
  }

  String getLocalizedThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return tr("general.theme_mode.dark");
      case ThemeMode.light:
        return tr("general.theme_mode.light");
      case ThemeMode.system:
        return tr("general.theme_mode.system");
    }
  }
}
