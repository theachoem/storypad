import 'package:flutter/material.dart';

class SpCupertinoFullPageSheetConfigurations extends StatelessWidget {
  const SpCupertinoFullPageSheetConfigurations({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: ColorScheme.of(context).surface,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      ),
      child: child,
    );
  }
}
