import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/gen/story_backgrounds.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';

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
    final themeProvider = Provider.of<DevicePreferencesProvider>(context);

    TextScaler textScaler = switch (preferences?.fontSize) {
      null => MediaQuery.textScalerOf(context),
      FontSizeOption.small => const TextScaler.linear(0.85),
      FontSizeOption.normal => const TextScaler.linear(1.0),
      FontSizeOption.large => const TextScaler.linear(1.15),
      FontSizeOption.extraLarge => const TextScaler.linear(1.3),
    };

    SpStoryPreferenceThemeConstructor themeConstructor = SpStoryPreferenceThemeConstructor(
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      context: context,
      fontFamily: preferences?.fontFamily ?? themeProvider.preferences.fontFamily,
      fontWeight: preferences?.fontWeight ?? themeProvider.preferences.fontWeight,
      preferences: preferences,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Theme(
        data: themeConstructor.theme,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: themeConstructor.scaffoldBackgroundColor)),
            buildImageBackground(themeConstructor),
            if (themeConstructor.overlayScaffoldBackgroundColor != null)
              Positioned.fill(child: Container(color: themeConstructor.overlayScaffoldBackgroundColor)),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildImageBackground(SpStoryPreferenceThemeConstructor themeConstructor) {
    if (themeConstructor.selectedBackground != null) {
      return Positioned.fill(
        child: SpFirestoreStorageDownloaderBuilder(
          key: ValueKey(themeConstructor.selectedBackground!.path),
          filePath: themeConstructor.selectedBackground!.path,
          builder: (context, file, failed) {
            if (file == null) return const SizedBox.shrink();

            return switch (themeConstructor.selectedBackground!.align) {
              .left => Image.file(file, fit: .cover, alignment: .centerLeft),
              .center => Image.file(file, fit: .cover, alignment: .center),
              .right => Image.file(file, fit: .cover, alignment: .centerRight),
            };
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class SpStoryPreferenceThemeConstructor {
  StoryBackground? get selectedBackground =>
      preferences?.backgroundImagePath != null ? StoryBackgrounds.byFilename[preferences!.backgroundImagePath!] : null;

  final bool isDarkMode;
  final BuildContext context;
  final String fontFamily;
  final FontWeight fontWeight;
  final StoryPreferencesDbModel? preferences;

  SpStoryPreferenceThemeConstructor({
    required this.isDarkMode,
    required this.context,
    required this.fontFamily,
    required this.fontWeight,
    required this.preferences,
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
    Color? seedColor = preferences?.colorSeed;

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
          isMonochrome(preferences?.colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      } else {
        colorScheme = getLightColorScheme(
          Colors.white,
          isMonochrome(preferences?.colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
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
    } else if (seedColor != null) {
      if (Theme.of(context).brightness == Brightness.dark) {
        colorScheme = getDarkColorScheme(
          seedColor,
          isMonochrome(preferences?.colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      } else {
        colorScheme = getLightColorScheme(
          seedColor,
          isMonochrome(preferences?.colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      }
      scaffoldBackgroundColor = getScaffoldBackgroundColor(colorScheme: colorScheme, preferences: preferences);
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
    required StoryPreferencesDbModel? preferences,
    required ColorScheme colorScheme,
  }) {
    bool darkMode = colorScheme.brightness == Brightness.dark;

    if (isMonochrome(preferences?.colorSeed) == true) {
      Color baseColor = darkMode ? Colors.black : Colors.white;
      return switch (preferences?.colorToneFallback) {
        0 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        33 || null => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.06), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.01), colorScheme.surface),
        99 => baseColor,
        _ => colorScheme.surface,
      };
    } else if (preferences?.colorSeed != null) {
      return switch (preferences?.colorToneFallback) {
        0 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        33 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 2), colorScheme.surface),
        99 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 3), colorScheme.surface),
        _ => colorScheme.readOnly.surface3,
      };
    } else {
      return switch (preferences?.colorToneFallback) {
        0 => colorScheme.surface,
        33 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11), colorScheme.surface),
        66 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05), colorScheme.surface),
        99 => Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.11 + 0.05 * 2), colorScheme.surface),
        _ => colorScheme.surface,
      };
    }
  }
}
