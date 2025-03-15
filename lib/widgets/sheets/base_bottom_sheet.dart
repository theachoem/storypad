import 'package:flutter/material.dart';

abstract class BaseBottomSheet {
  const BaseBottomSheet();

  Future<T?> show<T>({
    required BuildContext context,
    bool rootNavigator = false,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet(
      useRootNavigator: rootNavigator,
      context: context,
      showDragHandle: true,
      isScrollControlled: isScrollControlled,
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
