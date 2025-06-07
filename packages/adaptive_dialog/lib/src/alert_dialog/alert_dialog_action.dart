import 'package:adaptive_dialog/src/action_callback.dart';
import 'package:adaptive_dialog/src/modal_action_sheet/sheet_action.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Used for specifying showAlertDialog's actions.
@immutable
class AlertDialogAction<T> {
  const AlertDialogAction({
    required this.key,
    required this.label,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.textStyle = const TextStyle(),
  });

  final T key;
  final String label;

  /// Make font weight to bold(Only works for CupertinoStyle).
  final bool isDefaultAction;

  /// Make font color to destructive/error color(red).
  final bool isDestructiveAction;

  /// Change textStyle to another from default.
  ///
  /// Recommended to keep null.
  final TextStyle textStyle;
}

extension AlertDialogActionEx<T> on AlertDialogAction<T> {
  Widget convertToIOSDialogAction({
    required ActionCallback<T> onPressed,
  }) {
    return CupertinoDialogAction(
      isDefaultAction: isDefaultAction,
      isDestructiveAction: isDestructiveAction,
      textStyle: textStyle,
      onPressed: () => onPressed(key),
      child: Text(label),
    );
  }

  Widget convertToMaterialDialogAction({
    required ActionCallback<T> onPressed,
    required Color destructiveColor,
    required bool fullyCapitalized,
  }) {
    return TextButton(
      child: Text(
        fullyCapitalized ? label.toUpperCase() : label,
        style: textStyle.copyWith(
          color: isDestructiveAction ? destructiveColor : null,
        ),
      ),
      onPressed: () => onPressed(key),
    );
  }
}

extension AlertDialogActionListEx<T> on List<AlertDialogAction<T>> {
  List<SheetAction<T>> convertToSheetActions() =>
      where((a) => a.key != OkCancelResult.cancel)
          .map(
            (a) => SheetAction(
              key: a.key,
              label: a.label,
              isDefaultAction: a.isDefaultAction,
              isDestructiveAction: a.isDestructiveAction,
              textStyle: a.textStyle,
            ),
          )
          .toList();

  String? findCancelLabel() {
    try {
      return firstWhere((a) => a.key == OkCancelResult.cancel).label;
      // ignore: avoid_catching_errors
    } on StateError {
      return null;
    }
  }
}

// Result type of [showOkAlertDialog] or [showOkCancelAlertDialog].
enum OkCancelResult {
  ok,
  cancel,
}
