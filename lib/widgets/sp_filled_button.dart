import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;

/// The app's filled button: Cupertino-style on Cupertino builds, Material elsewhere.
class SpFilledButton extends StatelessWidget {
  const SpFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        disabledColor: Theme.of(context).disabledColor,
        sizeStyle: .medium,
        onPressed: onPressed,
        child: child,
      );
    }

    return FilledButton(onPressed: onPressed, child: child);
  }
}
