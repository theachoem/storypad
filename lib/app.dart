import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/locale_constants.dart';
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
        return MaterialApp(
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
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: preferences.timeFormat == TimeFormatOption.h24),
                child: child!,
              ),
            );
          },
        );
      }),
    );
  }
}
