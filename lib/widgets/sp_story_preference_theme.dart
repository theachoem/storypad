import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
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

  static final Map<String, ColorScheme> _cacheDarkColorSchemes = {};
  static final Map<String, ColorScheme> _cacheLightColorSchemes = {};

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

  StoryBackground? get selectedBackground =>
      preferences?.backgroundImagePath != null ? StoryBackgrounds.byFilename[preferences!.backgroundImagePath!] : null;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DevicePreferencesProvider>(context);

    ColorScheme colorScheme = getStoryColorScheme(preferences, context);
    Color? scaffoldBackgroundColor;
    Color? foregroundColor;

    if (selectedBackground != null) {
      scaffoldBackgroundColor = switch (selectedBackground!.textColor) {
        .black => Colors.white,
        .white => Colors.black,
      };
      foregroundColor = switch (selectedBackground!.textColor) {
        .black => Colors.black,
        .white => Colors.white,
      };
    } else {
      scaffoldBackgroundColor = getScaffoldBackgroundColor(
        preferences: preferences,
        colorScheme: colorScheme,
      );
    }

    TextScaler textScaler = switch (preferences?.fontSize) {
      null => MediaQuery.textScalerOf(context),
      FontSizeOption.small => const TextScaler.linear(0.85),
      FontSizeOption.normal => const TextScaler.linear(1.0),
      FontSizeOption.large => const TextScaler.linear(1.15),
      FontSizeOption.extraLarge => const TextScaler.linear(1.3),
    };

    final theme = AppTheme.getTheme(
      colorScheme: colorScheme,
      fontFamily: preferences?.fontFamily ?? themeProvider.preferences.fontFamily,
      fontWeight: preferences?.fontWeight ?? themeProvider.preferences.fontWeight,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Theme(
        data: foregroundColor == null
            ? theme
            : theme.copyWith(
                dividerColor: foregroundColor.withValues(alpha: 0.15),
                dividerTheme: theme.dividerTheme.copyWith(color: foregroundColor.withValues(alpha: 0.15)),
                iconTheme: theme.iconTheme.copyWith(color: foregroundColor),
                iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: foregroundColor)),
                textTheme: theme.textTheme.apply(bodyColor: foregroundColor),
                checkboxTheme: theme.checkboxTheme.copyWith(
                  side: BorderSide(
                    color: foregroundColor,
                    width: theme.checkboxTheme.side?.width ?? 2.0,
                  ),
                ),
              ),
        child: Stack(
          children: [
            buildBackground(scaffoldBackgroundColor),
            child,
          ],
        ),
      ),
    );
  }

  static bool isMonochrome(Color? colorSeed) {
    return colorSeed == Colors.black || colorSeed == Colors.white;
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

  Widget buildBackground(Color? scaffoldBackgroundColor) {
    if (selectedBackground != null) {
      return Positioned.fill(
        child: SpFirestoreStorageDownloaderBuilder(
          key: ValueKey(selectedBackground!.path),
          filePath: selectedBackground!.path,
          builder: (context, file, failed) {
            if (file == null || failed) {
              return Container(color: scaffoldBackgroundColor);
            }

            return switch (selectedBackground!.align) {
              .left => Image.file(file, fit: .cover, alignment: .centerLeft),
              .center => Image.file(file, fit: .cover, alignment: .center),
              .right => Image.file(file, fit: .cover, alignment: .centerRight),
            };
          },
        ),
      );
    } else {
      return Container(color: scaffoldBackgroundColor);
    }
  }

  ColorScheme getStoryColorScheme(
    StoryPreferencesDbModel? preferences,
    BuildContext context,
  ) {
    Color? seedColor = preferences?.colorSeed;

    if (selectedBackground != null) {
      return switch (selectedBackground!.textColor) {
        .black => getLightColorScheme(kDefaultColorSeed, DynamicSchemeVariant.monochrome),
        .white => getDarkColorScheme(kDefaultColorSeed, DynamicSchemeVariant.monochrome),
      };
    }

    if (seedColor == null) {
      return Theme.of(context).colorScheme;
    } else {
      if (Theme.of(context).brightness == Brightness.dark) {
        return getDarkColorScheme(
          seedColor,
          isMonochrome(preferences?.colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      } else {
        return getLightColorScheme(
          seedColor,
          isMonochrome(preferences?.colorSeed) ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      }
    }
  }

  Color? getRouteBackgroundColor(
    StoryPreferencesDbModel? preferences,
    BuildContext context,
  ) {
    if (preferences?.colorSeed == null) return null;
    if (isMonochrome(preferences?.colorSeed)) {
      return getStoryColorScheme(preferences, context).surface;
    } else {
      return getStoryColorScheme(preferences, context).readOnly.surface3;
    }
  }
}
