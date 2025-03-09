import 'package:flutter/material.dart';

class VisibleWhenNotified extends StatelessWidget {
  const VisibleWhenNotified({
    super.key,
    required this.notifier,
    required this.child,
    this.top,
    this.left,
    this.bottom,
    this.right,
  });

  final ValueNotifier<bool> notifier;
  final Widget child;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      child: child,
      builder: (context, visible, child) {
        return Visibility(
          visible: visible,
          child: child!,
        );
      },
    );
  }
}
