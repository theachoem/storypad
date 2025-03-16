import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';

abstract class BaseBottomSheet {
  const BaseBottomSheet();

  String get className => runtimeType.toString();

  String get analyticScreenName => className.replaceAll("BottomSheet", "");
  String get analyticScreenClass => className;

  Color? get barrierColor => null;
  Color? getBackgroundColor(BuildContext context) => null;

  Future<T?> show<T>({
    required BuildContext context,
  }) {
    AnalyticsService.instance.logViewSheet(bottomSheet: this);

    return showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      barrierColor: barrierColor,
      backgroundColor: getBackgroundColor(context),
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
          ),
          child: build(
            context,
            MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
          ),
        );
      },
    );
  }

  Widget buildBottomPadding(double bottomPadding) {
    return AnimatedContainer(
      curve: Curves.fastEaseInToSlowEaseOut,
      duration: Durations.long2,
      height: bottomPadding,
    );
  }

  Widget build(BuildContext context, double bottomPadding);
}
