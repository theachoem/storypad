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

  static final Map<Color, ColorScheme> _cacheDarkColorSchemes = {};
  static final Map<Color, ColorScheme> _cacheLightColorSchemes = {};

  bool isMonochrome(StoryPreferencesDbModel? preferences, BuildContext context) {
    final colorSeed = preferences?.colorSeed;
    return colorSeed == Colors.black || colorSeed == Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    ColorScheme colorScheme = getStoryColorScheme(preferences, context);

    Color? scaffoldBackgroundColor;

    if (isMonochrome(preferences, context) == true) {
      Color baseColor = AppTheme.isDarkMode(context) ? Colors.black : Colors.white;
      scaffoldBackgroundColor = switch (preferences?.colorToneFallback) {
        0 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        33 || null => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.06), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.01), colorScheme.surface),
        99 => baseColor,
        _ => colorScheme.surface,
      };
    } else if (preferences?.colorSeed != null) {
      scaffoldBackgroundColor = switch (preferences?.colorToneFallback) {
        0 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        33 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 2), colorScheme.surface),
        99 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 3), colorScheme.surface),
        _ => colorScheme.readOnly.surface3,
      };
    } else {
      scaffoldBackgroundColor = switch (preferences?.colorToneFallback) {
        0 => colorScheme.surface,
        33 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05), colorScheme.surface),
        99 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 2), colorScheme.surface),
        _ => colorScheme.surface,
      };
    }

    return Theme(
      data: AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: preferences?.fontFamily ?? themeProvider.theme.fontFamily,
        fontWeight: preferences?.fontWeight ?? themeProvider.theme.fontWeight,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      ),
      child: child,
    );
  }

  ColorScheme getStoryColorScheme(
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

  Color? getRouteBackgroundColor(
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
