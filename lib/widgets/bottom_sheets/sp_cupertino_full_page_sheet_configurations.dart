import 'package:flutter/material.dart';

class SpCupertinoFullPageSheetConfigurations extends StatelessWidget {
  const SpCupertinoFullPageSheetConfigurations({
    super.key,
    required this.child,
    required this.context,
  });

  final Widget child;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: ColorScheme.of(context).surface,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      ),
      child: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: child,
      ),
    );
  }
}
