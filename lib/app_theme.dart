import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/theme_provider.dart';

class AppTheme extends StatelessWidget {
  const AppTheme({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ThemeData theme, ThemeData darkTheme, ThemeMode themeMode) builder;

  // default text direction
  static bool ltr(BuildContext context) => Directionality.of(context) == TextDirection.ltr;
  static bool rtl(BuildContext context) => Directionality.of(context) == TextDirection.rtl;
  static bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static bool isMonochrome(BuildContext context) =>
      context.read<ThemeProvider>().theme.colorSeed == Colors.black ||
      context.read<ThemeProvider>().theme.colorSeed == Colors.white;

  static FontWeight getThemeFontWeight(BuildContext context, FontWeight fontWeight) {
    return calculateFontWeight(fontWeight, context.read<ThemeProvider>().theme.fontWeight);
  }

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
        builder: (ColorScheme lightScheme, ColorScheme darkScheme) {
          final theme = getTheme(
            colorScheme: lightScheme,
            fontFamily: provider.theme.fontFamily,
            fontWeight: provider.theme.fontWeight,
          );

          final darkTheme = getTheme(
            colorScheme: darkScheme,
            fontFamily: provider.theme.fontFamily,
            fontWeight: provider.theme.fontWeight,
          );

          return builder(context, theme, darkTheme, provider.themeMode);
        },
      );
    });
  }

  static ThemeData getTheme({
    required ColorScheme colorScheme,
    required String fontFamily,
    required FontWeight fontWeight,
    Color? scaffoldBackgroundColor,
  }) {
    scaffoldBackgroundColor ??= colorScheme.surface;

    bool blackout = colorScheme.onSurface == Colors.white;
    bool darkMode = colorScheme.brightness == Brightness.dark;
    bool lightMode = !darkMode;

    ThemeData baseTheme = darkMode ? ThemeData.dark() : ThemeData.light();

    TextStyle calculateTextStyle(TextStyle textStyle, FontWeight defaultFontWeight) {
      return textStyle.copyWith(fontWeight: calculateFontWeight(defaultFontWeight, fontWeight));
    }

    Map<TargetPlatform, PageTransitionsBuilder> pageTransitionBuilder = <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal, fillColor: scaffoldBackgroundColor)
    };

    Color? dividerColor = colorScheme.onSurface.withValues(alpha: 0.15);
    TargetPlatform platform = getPlatformByDartDefine();

    return baseTheme.copyWith(
      platform: platform,
      splashFactory: kIsCupertino ? NoSplash.splashFactory : null,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      pageTransitionsTheme: PageTransitionsTheme(builders: pageTransitionBuilder),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: kIsCupertino ? CircleBorder() : null,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: colorScheme.brightness,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        primaryColor: colorScheme.primary,
        primaryContrastingColor: colorScheme.onPrimary,
        textTheme: CupertinoTextThemeData(primaryColor: colorScheme.primary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.readOnly.surface5,
      ),
      appBarTheme: AppBarTheme(
        titleSpacing: NavigationToolbar.kMiddleSpacing,
        backgroundColor: lightMode ? colorScheme.surface : colorScheme.readOnly.surface1,
      ),
      tabBarTheme: TabBarTheme(
        dividerColor: dividerColor,
      ),
      drawerTheme: const DrawerThemeData(),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(color: dividerColor),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: dividerColor),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: blackout ? colorScheme.readOnly.surface2 : null),
      textTheme: GoogleFonts.getTextTheme(
        fontFamily,
        TextTheme(
          displayLarge: calculateTextStyle(baseTheme.textTheme.displayLarge!, FontWeight.w400),
          displayMedium: calculateTextStyle(baseTheme.textTheme.displayMedium!, FontWeight.w400),
          displaySmall: calculateTextStyle(baseTheme.textTheme.displaySmall!, FontWeight.w400),
          headlineLarge: calculateTextStyle(baseTheme.textTheme.headlineLarge!, FontWeight.w400),
          headlineMedium: calculateTextStyle(baseTheme.textTheme.headlineMedium!, FontWeight.w400),
          headlineSmall: calculateTextStyle(baseTheme.textTheme.headlineSmall!, FontWeight.w400),
          titleLarge: calculateTextStyle(baseTheme.textTheme.titleLarge!, FontWeight.w400),
          titleMedium: calculateTextStyle(baseTheme.textTheme.titleMedium!, FontWeight.w400),
          titleSmall: calculateTextStyle(baseTheme.textTheme.titleSmall!, FontWeight.w500),
          bodyLarge: calculateTextStyle(baseTheme.textTheme.bodyLarge!, FontWeight.w400),
          bodyMedium: calculateTextStyle(baseTheme.textTheme.bodyMedium!, FontWeight.w400),
          bodySmall: calculateTextStyle(baseTheme.textTheme.bodySmall!, FontWeight.w400),
          labelLarge: calculateTextStyle(baseTheme.textTheme.labelLarge!, FontWeight.w500),
          labelMedium: calculateTextStyle(baseTheme.textTheme.labelMedium!, FontWeight.w500),
          labelSmall: calculateTextStyle(baseTheme.textTheme.labelSmall!, FontWeight.w500),
        ),
      ),
    );
  }

  /// follow dart-define [kIsCupertino].
  static TargetPlatform getPlatformByDartDefine() {
    TargetPlatform platform = defaultTargetPlatform;
    bool isCupertioByPlatform = platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
    bool isMaterialByPlatform = platform == TargetPlatform.android ||
        platform == TargetPlatform.fuchsia ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows;

    if (kIsCupertino && !isCupertioByPlatform) {
      platform = TargetPlatform.iOS;
    }

    if (!kIsCupertino && !isMaterialByPlatform) {
      platform = TargetPlatform.android;
    }

    return platform;
  }

  Widget buildColorScheme({
    required ThemeProvider provider,
    required Widget Function(ColorScheme lightScheme, ColorScheme darkScheme) builder,
  }) {
    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      bool monochrome = provider.theme.colorSeed == Colors.black || provider.theme.colorSeed == Colors.white;

      ColorScheme lightScheme;
      ColorScheme darkScheme;

      if (provider.theme.colorSeed == null && lightDynamic != null && darkDynamic != null) {
        lightScheme = lightDynamic;
        darkScheme = darkDynamic;
      } else {
        lightScheme = ColorScheme.fromSeed(
          seedColor: provider.theme.colorSeed ?? kDefaultColorSeed,
          brightness: Brightness.light,
          dynamicSchemeVariant: monochrome ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );

        darkScheme = ColorScheme.fromSeed(
          seedColor: provider.theme.colorSeed ?? kDefaultColorSeed,
          brightness: Brightness.dark,
          dynamicSchemeVariant: monochrome ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
        );
      }

      return builder(lightScheme, darkScheme);
    });
  }

  static FontWeight calculateFontWeight(FontWeight defaultWeight, FontWeight currentWeight) {
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
