import 'package:flutter/material.dart';

class SpCupertinoFullPageSheetConfigurations extends StatelessWidget {
  const SpCupertinoFullPageSheetConfigurations({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 0.08 is base on _kBottomUpTween [ref: package:flutter/src/cupertino/sheet.dart]
    double bottomHeight = MediaQuery.of(context).size.height * 0.08;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: ColorScheme.of(context).surface,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomHeight),
          child: child,
        ),
      ),
    );
  }
}
