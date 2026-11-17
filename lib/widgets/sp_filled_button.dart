import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;

/// The app's filled button: Cupertino-style on Cupertino builds, Material elsewhere.
class SpFilledButton extends StatelessWidget {
  const SpFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
  }) : tonal = false;

  /// A quieter one: visible, but not the screen's main action.
  const SpFilledButton.tonal({
    super.key,
    required this.onPressed,
    required this.child,
  }) : tonal = true;

  final VoidCallback? onPressed;
  final Widget child;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    if (kIsCupertino) {
      if (tonal) return CupertinoButton.tinted(sizeStyle: .medium, onPressed: onPressed, child: child);

      return CupertinoButton.filled(
        disabledColor: Theme.of(context).disabledColor,
        sizeStyle: .medium,
        onPressed: onPressed,
        child: child,
      );
    }

    if (tonal) return FilledButton.tonal(onPressed: onPressed, child: child);
    return FilledButton(onPressed: onPressed, child: child);
  }
}
