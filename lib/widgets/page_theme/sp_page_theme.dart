import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/page_theme/sp_page_theme_constructor.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';

class SpPageTheme extends StatelessWidget {
  const SpPageTheme({
    super.key,
    required this.child,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.colorSeedValue,
    required this.colorTone,
    required this.backgroundImagePath,
  });

  final Widget child;
  final FontSizeOption? fontSize;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final int? colorSeedValue;
  final int? colorTone;
  final String? backgroundImagePath;

  factory SpPageTheme.device({
    required Widget child,
  }) {
    return SpPageTheme(
      fontSize: null,
      fontFamily: null,
      fontWeight: null,
      colorSeedValue: null,
      colorTone: null,
      backgroundImagePath: null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DevicePreferencesProvider>(context);

    TextScaler textScaler = switch (fontSize) {
      null => MediaQuery.textScalerOf(context),
      FontSizeOption.small => const TextScaler.linear(0.85),
      FontSizeOption.normal => const TextScaler.linear(1.0),
      FontSizeOption.large => const TextScaler.linear(1.15),
      FontSizeOption.extraLarge => const TextScaler.linear(1.3),
    };

    bool backgroundOverriden = backgroundImagePath != null || colorSeedValue != null;

    SpPageThemeConstructor themeConstructor = SpPageThemeConstructor(
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      context: context,
      fontFamily: fontFamily ?? themeProvider.preferences.fontFamily,
      fontWeight: fontWeight ?? themeProvider.preferences.fontWeight,
      colorSeedValue: backgroundOverriden ? colorSeedValue : themeProvider.preferences.colorSeedValue,
      colorTone: backgroundOverriden ? colorTone : null,
      backgroundImagePath: backgroundOverriden ? backgroundImagePath : themeProvider.preferences.backgroundImagePath,
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

  Widget buildImageBackground(SpPageThemeConstructor themeConstructor) {
    if (themeConstructor.selectedBackground != null) {
      return Positioned.fill(
        child: SpFirestoreStorageDownloaderBuilder(
          key: ValueKey(themeConstructor.selectedBackground!.path),
          filePath: themeConstructor.selectedBackground!.path,
          builder: (context, file, failed) {
            if (file == null) return const SizedBox.shrink();

            return LayoutBuilder(
              builder: (context, constraints) {
                return Image.file(
                  file,
                  fit: .cover,

                  // The image is rendered to fill the widget, but BoxFit.cover crops it (only ~1/3 of the image width is visible).
                  // To ensure the displayed part stays sharp, we multiply the widget width by 3 when setting cacheWidth.
                  // Using cacheWidth improves performance by decoding a properly sized image.
                  cacheWidth: (constraints.maxWidth * 3 * MediaQuery.of(context).devicePixelRatio).round(),
                  alignment: switch (themeConstructor.selectedBackground!.align) {
                    .left => .centerLeft,
                    .center => .center,
                    .right => .centerRight,
                  },
                );
              },
            );
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
