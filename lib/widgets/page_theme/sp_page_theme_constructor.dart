import 'package:flutter/material.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/gen/story_backgrounds.dart';

class SpPageThemeConstructor {
  StoryBackground? get selectedBackground =>
      backgroundImagePath != null ? StoryBackgrounds.byFilename[backgroundImagePath!] : null;

  final bool isDarkMode;
  final BuildContext context;
  final String fontFamily;
  final FontWeight fontWeight;
  final int? colorSeedValue;
  final int? colorTone;
  final String? backgroundImagePath;

  Color? get colorSeed => colorSeedValue != null ? Color(colorSeedValue!) : null;
  int get colorToneFallback => colorTone ?? 0;

  SpPageThemeConstructor({
    required this.isDarkMode,
    required this.context,
    required this.fontFamily,
    required this.fontWeight,
    required this.colorSeedValue,
    required this.colorTone,
    required this.backgroundImagePath,
  }) {
    _construct();
  }

  Color? scaffoldBackgroundColor;
  Color? overlayScaffoldBackgroundColor;
  Color? overrideForegroundColor;

  late ColorScheme colorScheme;
  late ThemeData theme;

  static final Map<String, ColorScheme> _cacheDarkColorSchemes = {};
  static final Map<String, ColorScheme> _cacheLightColorSchemes = {};

  bool get backgroundForLightMode => selectedBackground?.textColor == StoryBackgroundTextColor.black;
  bool get backgroundForDarkMode => selectedBackground?.textColor == StoryBackgroundTextColor.white;

  void _construct() {
    if (selectedBackground != null) {
      // 1. when background is for light mode, and user in dark mode,
      // we do following check for eye comfort.
      if (backgroundForLightMode && !isDarkMode) {
        overlayScaffoldBackgroundColor = null;
        overrideForegroundColor = Colors.black.withValues(alpha: 0.87);
      } else if (backgroundForLightMode && isDarkMode) {
        overlayScaffoldBackgroundColor = Colors.black.withValues(alpha: 0.5);
        overrideForegroundColor = Colors.white;
      }
      //
      // 2. for background for dark mode, it's fine to use directly on both dark/light mode.
      else if (backgroundForDarkMode) {
        overlayScaffoldBackgroundColor = null;
        overrideForegroundColor = Colors.white;
      }

      if (overrideForegroundColor == Colors.white) {
        colorScheme = getDarkColorScheme(
          Colors.black,
          isMonochrome(colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      } else {
        colorScheme = getLightColorScheme(
          Colors.white,
          isMonochrome(colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      }

      scaffoldBackgroundColor = colorScheme.surface;
      theme = AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      );

      theme = theme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        dividerColor: overrideForegroundColor!.withValues(alpha: 0.15),
        dividerTheme: theme.dividerTheme.copyWith(color: overrideForegroundColor!.withValues(alpha: 0.15)),
        iconTheme: theme.iconTheme.copyWith(color: overrideForegroundColor!),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: overrideForegroundColor!),
        ),
        textTheme: theme.textTheme.apply(bodyColor: overrideForegroundColor!),
        checkboxTheme: theme.checkboxTheme.copyWith(
          side: BorderSide(
            color: overrideForegroundColor!,
            width: theme.checkboxTheme.side?.width ?? 2.0,
          ),
        ),
      );
    } else if (colorSeed != null) {
      if (Theme.of(context).brightness == Brightness.dark) {
        colorScheme = getDarkColorScheme(
          colorSeed!,
          isMonochrome(colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      } else {
        colorScheme = getLightColorScheme(
          colorSeed!,
          isMonochrome(colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      }
      scaffoldBackgroundColor = getScaffoldBackgroundColor(
        colorScheme: colorScheme,
        colorSeed: colorSeed,
        colorToneFallback: colorToneFallback,
      );
      theme = AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      );
    } else {
      colorScheme = Theme.of(context).colorScheme;
      scaffoldBackgroundColor = colorScheme.surface;
      theme = AppTheme.getTheme(
        colorScheme: colorScheme,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      );
    }
  }

  static bool isMonochrome(Color? colorSeed) {
    return colorSeed == Colors.black || colorSeed == Colors.white;
  }

  static ColorScheme getLightColorScheme(Color seedColor, DynamicSchemeVariant dynamicSchemeVariant) {
    return _cacheLightColorSchemes['${seedColor.toARGB32()}-${dynamicSchemeVariant.name}'] ??= ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: dynamicSchemeVariant,
    );
  }

  static ColorScheme getDarkColorScheme(
    Color seedColor,
    DynamicSchemeVariant dynamicSchemeVariant,
  ) {
    return _cacheDarkColorSchemes['${seedColor.toARGB32()}-${dynamicSchemeVariant.name}'] ??= ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: dynamicSchemeVariant,
    );
  }

  static Color? getScaffoldBackgroundColor({
    required Color? colorSeed,
    required int? colorToneFallback,
    required ColorScheme colorScheme,
  }) {
    bool darkMode = colorScheme.brightness == Brightness.dark;

    if (isMonochrome(colorSeed) == true) {
      Color baseColor = darkMode ? Colors.black : Colors.white;
      return switch (colorToneFallback) {
        0 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        33 || null => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.06), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.01), colorScheme.surface),
        99 => baseColor,
        _ => colorScheme.surface,
      };
    } else if (colorSeed != null) {
      return switch (colorToneFallback) {
        0 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        33 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 2), colorScheme.surface),
        99 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 3), colorScheme.surface),
        _ => colorScheme.readOnly.surface3,
      };
    } else {
      return switch (colorToneFallback) {
        0 => colorScheme.surface,
        33 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05), colorScheme.surface),
        99 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 2), colorScheme.surface),
        _ => colorScheme.surface,
      };
    }
  }
}
