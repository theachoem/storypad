import 'dart:io';
import 'package:flutter/widgets.dart';

class DesktopMainMenuPadding extends StatelessWidget {
  const DesktopMainMenuPadding({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);

    double mainMenuPadding = 0;
    if (Platform.isMacOS) mainMenuPadding = 24;

    if (mainMenuPadding == 0) {
      return child;
    }

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(top: mediaQuery.padding.top + mainMenuPadding),
      ),
      child: child,
    );
  }
}
