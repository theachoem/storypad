import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad/views/root/root_view.dart';

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      path: 'translations',
      supportedLocales: kSupportedLocales,
      fallbackLocale: kFallbackLocale,
      startLocale: kFallbackLocale,
      child: AppTheme(
        builder: (context, preferences, theme, darkTheme, themeMode) {
          MediaQueryData mediaQuery = MediaQuery.of(context);
          TextScaler textScaler = switch (preferences.fontSize) {
            null => MediaQuery.textScalerOf(context),
            FontSizeOption.small => const TextScaler.linear(0.85),
            FontSizeOption.normal => const TextScaler.linear(1.0),
            FontSizeOption.large => const TextScaler.linear(1.15),
            FontSizeOption.extraLarge => const TextScaler.linear(1.3),
          };

          double mainMenuPadding = 0;

          // Add padding for macOS main menu bar.
          if (Platform.isMacOS) mainMenuPadding = 24;

          return MediaQuery(
            data: mediaQuery.copyWith(
              padding: mediaQuery.padding.copyWith(top: mediaQuery.padding.top + mainMenuPadding),
              textScaler: textScaler,
              alwaysUse24HourFormat: preferences.timeFormat == TimeFormatOption.h24,
            ),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: theme,
              darkTheme: darkTheme,
              home: const RootView(),
              localizationsDelegates: [
                ...EasyLocalization.of(context)!.delegates,
                DefaultCupertinoLocalizations.delegate,
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
                FlutterQuillLocalizations.delegate,
              ],
              supportedLocales: context.supportedLocales,
              locale: context.locale,
            ),
          );
        },
      ),
    );
  }
}
