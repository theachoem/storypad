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
    ColorScheme colorScheme;

    if (seedColor == null) {
      colorScheme = Theme.of(context).colorScheme;
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Theme.of(context).brightness,
        dynamicSchemeVariant: monochrome ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
      );
    }

    return Theme(
      data: AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: preferences?.fontFamily ?? themeProvider.theme.fontFamily,
        fontWeight: preferences?.fontWeight ?? themeProvider.theme.fontWeight,
        scaffoldBackgroundColor: preferences?.colorSeed != null ? colorScheme.readOnly.surface3 : null,
      ),
      child: child,
    );
  }
}
