import 'package:flutter/material.dart';
import 'package:spooky/app_theme.dart';
import 'package:spooky/views/home/home_view.dart';
import 'package:spooky/widgets/sp_local_auth_wrapper.dart';

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
        builder: (context, child) {
          return SpLocalAuthWrapper(child: child!);
        },
      );
    });
  }
}
