import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_theme_mode_sheet.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_setting_icon_badge.dart';

class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({
    super.key,
    required this.weekday,
    required this.currentThemeMode,
    required this.onChanged,
  });

  final int weekday;

  final ThemeMode currentThemeMode;
  final void Function(ThemeMode themeMode) onChanged;

  static Widget globalTheme({required int weekday}) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return ThemeModeTile(
          weekday: weekday,
          currentThemeMode: provider.preferences.themeMode,
          onChanged: (ThemeMode themeMode) => provider.setThemeMode(themeMode),
        );
      },
    );
  }

  bool isDarkMode(BuildContext context) {
    if (currentThemeMode == ThemeMode.system) {
      Brightness? brightness = View.maybeOf(context)?.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return currentThemeMode == ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SpSettingIconBadge.widget(
        weekday: weekday,
        child: SpAnimatedIcons(
          duration: Durations.medium4,
          firstChild: Icon(SpIcons.darkMode, color: ColorFromDayService(context: context).getForeground(), size: 20),
          secondChild: Icon(SpIcons.lightMode, color: ColorFromDayService(context: context).getForeground(), size: 20),
          showFirst: isDarkMode(context),
        ),
      ),
      title: Text(tr('list_tile.theme_mode.title')),
      subtitle: Text(getLocalizedThemeMode(currentThemeMode)),
      onTap: () {
        SpThemeModeSheet(
          themeMode: currentThemeMode,
          onChanged: onChanged,
        ).show(context: context);
      },
    );
  }

  static String getLocalizedThemeMode(ThemeMode mode) {
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
