import 'package:flutter/widgets.dart';

/// Used for specifying showModalActionSheet's actions.
@immutable
class SheetAction<T> {
  const SheetAction({
    required this.label,
    this.textStyle = const TextStyle(),
    this.key,
    this.icon,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  final String label;

  /// Only works for Material Style
  final IconData? icon;

  /// Used for checking selection result
  final T? key;

  /// Make font weight to bold(Only works for CupertinoStyle).
  final bool isDefaultAction;

  /// Make font color to destructive/error color(red).
  final bool isDestructiveAction;

  final TextStyle textStyle;
}
