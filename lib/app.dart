import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad/views/home/home_view.dart';

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
      child: AppTheme(builder: (context, preferences, theme, darkTheme, themeMode) {
        TextScaler textScaler = switch (preferences.fontSize) {
          null => MediaQuery.textScalerOf(context),
          FontSizeOption.small => const TextScaler.linear(0.85),
          FontSizeOption.normal => const TextScaler.linear(1.0),
          FontSizeOption.large => const TextScaler.linear(1.15),
          FontSizeOption.extraLarge => const TextScaler.linear(1.3),
        };

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            alwaysUse24HourFormat: preferences.timeFormat == TimeFormatOption.h24,
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: theme,
            darkTheme: darkTheme,
            home: const HomeView(),
            localizationsDelegates: [
              ...EasyLocalization.of(context)!.delegates,
              DefaultCupertinoLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: (context, child) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: child!,
              );
            },
          ),
        );
      }),
    );
  }
}
