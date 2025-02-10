import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';

class SpEndDrawerTheme extends StatelessWidget {
  const SpEndDrawerTheme({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool blackout = ColorScheme.of(context).surface == Colors.black;

    return Theme(
      data: blackout
          ? Theme.of(context).copyWith(
              drawerTheme: DrawerTheme.of(context).copyWith(backgroundColor: ColorScheme.of(context).readOnly.surface2),
              scaffoldBackgroundColor: ColorScheme.of(context).readOnly.surface2,
              appBarTheme: AppBarTheme.of(context).copyWith(backgroundColor: ColorScheme.of(context).readOnly.surface4),
            )
          : Theme.of(context),
      child: child,
    );
  }
}
