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
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeLeft: true,
        removeRight: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
          child: child,
        ),
      ),
    );
  }
}
