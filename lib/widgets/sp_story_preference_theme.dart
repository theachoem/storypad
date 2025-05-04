import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
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

  static final Map<Color, ColorScheme> _cacheDarkColorSchemes = {};
  static final Map<Color, ColorScheme> _cacheLightColorSchemes = {};

  static bool isMonochrome(StoryPreferencesDbModel? preferences, BuildContext context) {
    final colorSeed = preferences?.colorSeed ?? context.read<ThemeProvider>().theme.colorSeed ?? kDefaultColorSeed;
    return colorSeed == Colors.black || colorSeed == Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    ColorScheme colorScheme = getStoryColorScheme(preferences, context);

    return Theme(
      data: AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: preferences?.fontFamily ?? themeProvider.theme.fontFamily,
        fontWeight: preferences?.fontWeight ?? themeProvider.theme.fontWeight,
        scaffoldBackgroundColor:
            isMonochrome(preferences, context) == true ? colorScheme.surface : colorScheme.readOnly.surface3,
      ),
      child: child,
    );
  }

  static ColorScheme getStoryColorScheme(
    StoryPreferencesDbModel? preferences,
    BuildContext context,
  ) {
    Color? seedColor = preferences?.colorSeed;
    if (seedColor == null) {
      return Theme.of(context).colorScheme;
    } else {
      if (Theme.of(context).brightness == Brightness.dark) {
        return _cacheDarkColorSchemes[seedColor] ??= ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Theme.of(context).brightness,
          dynamicSchemeVariant:
              isMonochrome(preferences, context) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      } else {
        return _cacheLightColorSchemes[seedColor] ??= ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Theme.of(context).brightness,
          dynamicSchemeVariant:
              isMonochrome(preferences, context) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      }
    }
  }

  static Color? getRouteBackgroundColor(
    StoryPreferencesDbModel? preferences,
    BuildContext context,
  ) {
    if (preferences?.colorSeed == null) return null;
    if (isMonochrome(preferences, context)) {
      return getStoryColorScheme(preferences, context).surface;
    } else {
      return getStoryColorScheme(preferences, context).readOnly.surface3;
    }
  }
}
