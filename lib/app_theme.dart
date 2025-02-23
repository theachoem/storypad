import 'dart:math' as math;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/routes/utils/animated_page_route.dart';

class AppTheme extends StatelessWidget {
  const AppTheme({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ThemeData theme, ThemeData darkTheme, ThemeMode themeMode) builder;

  // default text direction
  static bool ltr(BuildContext context) => Directionality.of(context) == TextDirection.ltr;
  static bool rtl(BuildContext context) => Directionality.of(context) == TextDirection.rtl;

  static T? getDirectionValue<T extends Object>(BuildContext context, T? rtlValue, T? ltrValue) {
    if (Directionality.of(context) == TextDirection.rtl) {
      return rtlValue;
    } else {
      return ltrValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, provider, child) {
      return buildColorScheme(
        provider: provider,
        builder: (ColorScheme lightDynamic, ColorScheme darkDynamic) {
          final theme = getTheme(ThemeData.light(), lightDynamic, provider);
          final darkTheme = getTheme(ThemeData.dark(), darkDynamic, provider);
          return builder(context, theme, darkTheme, provider.themeMode);
        },
      );
    });
  }

  ThemeData getTheme(ThemeData theme, ColorScheme colorScheme, ThemeProvider provider) {
    bool blackout = colorScheme.onSurface == Colors.white;
    bool darkMode = colorScheme.brightness == Brightness.dark;
    bool lightMode = !darkMode;

    TextStyle calculateTextStyle(TextStyle textStyle, FontWeight defaultFontWeight) {
      return textStyle.copyWith(fontWeight: calculateFontWeight(defaultFontWeight, provider.theme.fontWeight));
    }

    Map<TargetPlatform, PageTransitionsBuilder> pageTransitionBuilder = <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.vertical,
        fillColor: colorScheme.surface,
      ),
    };

    Color? dividerColor = colorScheme.onSurface.withValues(alpha: 0.15);

    return theme.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      colorScheme: colorScheme,
      pageTransitionsTheme: PageTransitionsTheme(builders: pageTransitionBuilder),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.readOnly.surface5,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        titleSpacing: NavigationToolbar.kMiddleSpacing,
        backgroundColor: lightMode ? colorScheme.surface : colorScheme.readOnly.surface1,
      ),
      tabBarTheme: TabBarTheme(
        dividerColor: dividerColor,
      ),
      drawerTheme: const DrawerThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        endShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(color: dividerColor),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: blackout ? colorScheme.readOnly.surface2 : null),
      textTheme: GoogleFonts.getTextTheme(
        provider.theme.fontFamily,
        TextTheme(
          displayLarge: calculateTextStyle(theme.textTheme.displayLarge!, FontWeight.w400),
          displayMedium: calculateTextStyle(theme.textTheme.displayMedium!, FontWeight.w400),
          displaySmall: calculateTextStyle(theme.textTheme.displaySmall!, FontWeight.w400),
          headlineLarge: calculateTextStyle(theme.textTheme.headlineLarge!, FontWeight.w400),
          headlineMedium: calculateTextStyle(theme.textTheme.headlineMedium!, FontWeight.w400),
          headlineSmall: calculateTextStyle(theme.textTheme.headlineSmall!, FontWeight.w400),
          titleLarge: calculateTextStyle(theme.textTheme.titleLarge!, FontWeight.w400),
          titleMedium: calculateTextStyle(theme.textTheme.titleMedium!, FontWeight.w400),
          titleSmall: calculateTextStyle(theme.textTheme.titleSmall!, FontWeight.w500),
          bodyLarge: calculateTextStyle(theme.textTheme.bodyLarge!, FontWeight.w400),
          bodyMedium: calculateTextStyle(theme.textTheme.bodyMedium!, FontWeight.w400),
          bodySmall: calculateTextStyle(theme.textTheme.bodySmall!, FontWeight.w400),
          labelLarge: calculateTextStyle(theme.textTheme.labelLarge!, FontWeight.w500),
          labelMedium: calculateTextStyle(theme.textTheme.labelMedium!, FontWeight.w500),
          labelSmall: calculateTextStyle(theme.textTheme.labelSmall!, FontWeight.w500),
        ),
      ),
    );
  }

  Widget buildColorScheme({
    required ThemeProvider provider,
    required Widget Function(ColorScheme lightDynamic, ColorScheme darkDynamic) builder,
  }) {
    if (provider.theme.colorSeed == Colors.black || provider.theme.colorSeed == Colors.white) {
      final darkScheme = ColorScheme.dark(
        outline: Colors.white10,
        outlineVariant: Colors.white24,
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        error: Colors.red[200]!,
        onError: Colors.white,
        surface: Color.alphaBlend(
          Colors.white.withValues(alpha: 0.05),
          Colors.black,
        ),
        onSurface: Colors.white,
        surfaceContainerHighest: Colors.white,
        secondaryContainer: Color.alphaBlend(Colors.white.withValues(alpha: 0.14), Colors.black),
        onSecondaryContainer: Colors.white,
      );

      final lightScheme = ColorScheme.light(
        outline: Colors.black12,
        outlineVariant: Colors.black26,
        primary: Colors.black87,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        error: Colors.red[600]!,
        onError: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerHighest: Colors.white,
        secondaryContainer: Color.alphaBlend(Colors.white.withValues(alpha: 0.14), Colors.white),
        onSecondaryContainer: Colors.black,
      );

      return builder(lightScheme, darkScheme);
    } else if (provider.theme.colorSeed != null) {
      final lightScheme = ColorScheme.fromSeed(seedColor: provider.theme.colorSeed!, brightness: Brightness.light);
      final darkScheme = ColorScheme.fromSeed(seedColor: provider.theme.colorSeed!, brightness: Brightness.dark);
      return builder(lightScheme, darkScheme);
    } else {
      return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        lightDynamic ??= ColorScheme.fromSeed(seedColor: kDefaultColorSeed, brightness: Brightness.light);
        darkDynamic ??= ColorScheme.fromSeed(seedColor: kDefaultColorSeed, brightness: Brightness.dark);

        return builder(lightDynamic, darkDynamic);
      });
    }
  }

  FontWeight calculateFontWeight(FontWeight defaultWeight, FontWeight currentWeight) {
    int changeBy = defaultWeight == FontWeight.w400 ? 0 : 1;
    Map<int, FontWeight> fontWeights = {
      0: FontWeight.w100,
      1: FontWeight.w200,
      2: FontWeight.w300,
      3: FontWeight.w400,
      4: FontWeight.w500,
      5: FontWeight.w600,
      6: FontWeight.w700,
      7: FontWeight.w800,
      8: FontWeight.w900,
    };
    int index = currentWeight.index + changeBy;
    return fontWeights[math.max(math.min(8, index), 0)]!;
  }
}
