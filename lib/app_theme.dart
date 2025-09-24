import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/device_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';

class AppTheme extends StatelessWidget {
  const AppTheme({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    DevicePreferencesObject preferences,
    ThemeData lightTheme,
    ThemeData darkTheme,
    ThemeMode preferencesMode,
  ) builder;

  // default text direction
  static bool ltr(BuildContext context) => Directionality.of(context) == TextDirection.ltr;
  static bool rtl(BuildContext context) => Directionality.of(context) == TextDirection.rtl;
  static bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static bool isMonochrome(BuildContext context) =>
      context.read<DevicePreferencesProvider>().preferences.colorSeed == Colors.black ||
      context.read<DevicePreferencesProvider>().preferences.colorSeed == Colors.white;

  static T? getDirectionValue<T extends Object>(BuildContext context, T? rtlValue, T? ltrValue) {
    if (Directionality.of(context) == TextDirection.rtl) {
      return rtlValue;
    } else {
      return ltrValue;
    }
  }

  static FontWeight getThemeFontWeight(BuildContext context, FontWeight defaultWeight) {
    FontWeight preferredFontWeight = context.read<DevicePreferencesProvider>().preferences.fontWeight;

    final fontWeights = {
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

    int indexOf(FontWeight weight) => fontWeights.entries.firstWhere((e) => e.value == weight).key;

    final diff = indexOf(defaultWeight) - indexOf(FontWeight.w400);
    final newIndex = (indexOf(preferredFontWeight) + diff).clamp(0, 8);

    return fontWeights[newIndex]!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevicePreferencesProvider>(builder: (context, provider, child) {
      return buildColorScheme(
        provider: provider,
        builder: (ColorScheme lightScheme, ColorScheme darkScheme) {
          final isDarkMode = provider.isDarkModeBaseOnThemeMode(context);

          final lightTheme = getTheme(
            colorScheme: lightScheme,
            fontFamily: provider.preferences.fontFamily,
            fontWeight: provider.preferences.fontWeight,
          );

          final darkTheme = getTheme(
            colorScheme: darkScheme,
            fontFamily: provider.preferences.fontFamily,
            fontWeight: provider.preferences.fontWeight,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ),
            child: builder(context, provider.preferences, lightTheme, darkTheme, provider.themeMode),
          );
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

    bool darkMode = colorScheme.brightness == Brightness.dark;
    bool lightMode = !darkMode;

    ThemeData baseTheme = darkMode ? ThemeData.dark() : ThemeData.light();

    TextStyle calculateTextStyle(TextStyle textStyle, FontWeight defaultFontWeight) {
      return textStyle.copyWith(fontWeight: _calculateFontWeight(defaultFontWeight, fontWeight));
    }

    Color? dividerColor = colorScheme.onSurface.withValues(alpha: 0.15);
    TargetPlatform platform = getPlatformByDartDefine();

    return baseTheme.copyWith(
      platform: platform,
      splashFactory: kIsCupertino ? NoSplash.splashFactory : null,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      pageTransitionsTheme: getPageTransitionTheme(fillColor: scaffoldBackgroundColor),
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
      tabBarTheme: TabBarThemeData(
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

  static PageTransitionsTheme getPageTransitionTheme({
    Color? fillColor,
  }) {
    final pageTransitionsTheme = PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: fillColor,
      ),
    });
    return pageTransitionsTheme;
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
    required DevicePreferencesProvider provider,
    required Widget Function(ColorScheme lightScheme, ColorScheme darkScheme) builder,
  }) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        bool hasDynamicColor = lightDynamic != null && darkDynamic != null;
        bool useDynamicColor = provider.preferences.colorSeed == null;

        if (hasDynamicColor && useDynamicColor) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          bool monochrome =
              provider.preferences.colorSeed == Colors.black || provider.preferences.colorSeed == Colors.white;

          lightScheme = ColorScheme.fromSeed(
            seedColor: provider.preferences.colorSeed ?? kDefaultColorSeed,
            brightness: Brightness.light,
            dynamicSchemeVariant: monochrome ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
          );

          darkScheme = ColorScheme.fromSeed(
            seedColor: provider.preferences.colorSeed ?? kDefaultColorSeed,
            brightness: Brightness.dark,
            dynamicSchemeVariant: monochrome ? DynamicSchemeVariant.monochrome : DynamicSchemeVariant.tonalSpot,
          );
        }

        return builder(lightScheme, darkScheme);
      },
    );
  }

  static FontWeight _calculateFontWeight(FontWeight defaultWeight, FontWeight preferredFontWeight) {
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

    int index = preferredFontWeight.index + changeBy;
    return fontWeights[math.max(math.min(8, index), 0)]!;
  }
}
