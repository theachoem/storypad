import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/widgets/sp_local_auth_wrapper.dart';

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppTheme(builder: (theme, darkTheme, themeMode) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: theme,
        darkTheme: darkTheme,
        home: const HomeView(),
        locale: context.read<ThemeProvider>().currentLocale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('km'),
          Locale('ar'),
        ],
        builder: (context, child) {
          return SpLocalAuthWrapper(child: child!);
        },
      );
    });
  }
}
