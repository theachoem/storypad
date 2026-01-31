import 'dart:io';
import 'package:flutter/material.dart';

class SpScrollConfiguration extends StatelessWidget {
  const SpScrollConfiguration({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No need to modify scroll behavior on mobile platforms.
    if (Platform.isAndroid || Platform.isIOS) {
      return child;
    }

    // On desktop, there is auto added trailing icon.
    // So it does not look nice with scrollbars at all.
    // Hiding scrollbars to make it look better. Scrollbar is truly optional anyways for tags view.
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: child,
    );
  }
}
