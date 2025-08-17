import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/app_theme.dart';

void main() {
  group('AppTheme.getTheme navigation bar configuration', () {
    test('applies correct system navigation bar color for light theme', () {
      const lightColorScheme = ColorScheme.light();
      final theme = AppTheme.getTheme(
        colorScheme: lightColorScheme,
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.normal,
      );

      expect(theme.appBarTheme.systemOverlayStyle, isNotNull);
      expect(
        theme.appBarTheme.systemOverlayStyle!.systemNavigationBarColor,
        equals(lightColorScheme.surface),
      );
      expect(
        theme.appBarTheme.systemOverlayStyle!.systemNavigationBarIconBrightness,
        equals(Brightness.dark),
      );
    });

    test('applies correct system navigation bar color for dark theme', () {
      const darkColorScheme = ColorScheme.dark();
      final theme = AppTheme.getTheme(
        colorScheme: darkColorScheme,
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.normal,
      );

      expect(theme.appBarTheme.systemOverlayStyle, isNotNull);
      expect(
        theme.appBarTheme.systemOverlayStyle!.systemNavigationBarColor,
        equals(darkColorScheme.surface),
      );
      expect(
        theme.appBarTheme.systemOverlayStyle!.systemNavigationBarIconBrightness,
        equals(Brightness.light),
      );
    });

    test('applies custom scaffold background color to navigation bar', () {
      const lightColorScheme = ColorScheme.light();
      const customBackgroundColor = Colors.blue;
      
      final theme = AppTheme.getTheme(
        colorScheme: lightColorScheme,
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.normal,
        scaffoldBackgroundColor: customBackgroundColor,
      );

      expect(
        theme.appBarTheme.systemOverlayStyle!.systemNavigationBarColor,
        equals(customBackgroundColor),
      );
    });

    test('configures transparent status bar', () {
      const lightColorScheme = ColorScheme.light();
      final theme = AppTheme.getTheme(
        colorScheme: lightColorScheme,
        fontFamily: 'Quicksand',
        fontWeight: FontWeight.normal,
      );

      expect(
        theme.appBarTheme.systemOverlayStyle!.statusBarColor,
        equals(Colors.transparent),
      );
    });
  });

}