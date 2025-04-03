import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/theme_provider.dart';

class SpStoryPreferenceTheme extends StatelessWidget {
  const SpStoryPreferenceTheme({
    super.key,
    required this.child,
    required this.preferences,
  });

  final Widget child;
  final StoryPreferencesDbModel? preferences;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    Color? seedColor = preferences?.colorSeed ?? themeProvider.theme.colorSeed;
    bool monochrome = seedColor == Colors.black || seedColor == Colors.white;
    Brightness brightness;

    switch (preferences?.themeMode) {
      case ThemeMode.system:
      case null:
        brightness = ColorScheme.of(context).brightness;
        break;
      case ThemeMode.dark:
        brightness = Brightness.dark;
        break;
      case ThemeMode.light:
        brightness = Brightness.light;
        break;
    }

    ColorScheme colorScheme;

    if (seedColor == null) {
      // TODO: this does not custom theme yet.
      colorScheme = Theme.of(context).colorScheme;
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        dynamicSchemeVariant: monochrome ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
      );
    }

    return Theme(
      data: AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: preferences?.fontFamily ?? context.read<ThemeProvider>().theme.fontFamily,
        fontWeight: preferences?.fontWeight ?? context.read<ThemeProvider>().theme.fontWeight,
      ).copyWith(scaffoldBackgroundColor: preferences?.colorSeed != null ? colorScheme.readOnly.surface3 : null),
      child: child,
    );
  }
}
