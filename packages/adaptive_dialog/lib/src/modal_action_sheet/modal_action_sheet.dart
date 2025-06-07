// ignore_for_file: depend_on_referenced_packages

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_dialog/src/modal_action_sheet/material_modal_action_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'cupertino_modal_action_sheet.dart';

export 'sheet_action.dart';

/// Show modal action sheet, whose appearance is adaptive according to platform

/// The [isDismissible] parameter only works for material style and it specifies
/// whether the bottom sheet will be dismissed when user taps on the scrim.
@useResult
Future<T?> showModalActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  List<SheetAction<T>> actions = const [],
  String? cancelLabel,
  AdaptiveStyle? style,
  bool isDismissible = true,
  bool useRootNavigator = true,
  MaterialModalActionSheetConfiguration? materialConfiguration,
  bool canPop = true,
  PopInvokedWithResultCallback<T>? onPopInvokedWithResult,
  AdaptiveDialogBuilder? builder,
  RouteSettings? routeSettings,
}) {
  void pop({required BuildContext context, required T? key}) => Navigator.of(
        context,
        rootNavigator: useRootNavigator,
      ).pop(key);

  final theme = Theme.of(context);
  final adaptiveStyle = style ?? AdaptiveDialog.instance.defaultStyle;
  return adaptiveStyle.isMaterial(theme)
      ? showModalBottomSheet(
          context: context,
          isScrollControlled: materialConfiguration != null,
          isDismissible: isDismissible,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          builder: (context) {
            final sheet = MaterialModalActionSheet(
              onPressed: (key) => pop(context: context, key: key),
              title: title,
              message: message,
              actions: actions,
              materialConfiguration: materialConfiguration,
              canPop: canPop,
              onPopInvokedWithResult: onPopInvokedWithResult,
            );
            return builder == null ? sheet : builder(context, sheet);
          },
        )
      : showCupertinoModalPopup(
          context: context,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          builder: (context) {
            final sheet = CupertinoModalActionSheet(
              onPressed: (key) => pop(context: context, key: key),
              title: title,
              message: message,
              actions: actions,
              cancelLabel: cancelLabel,
              canPop: canPop,
              onPopInvokedWithResult: onPopInvokedWithResult,
            );
            return builder == null ? sheet : builder(context, sheet);
          },
        );
}

@immutable
class MaterialModalActionSheetConfiguration {
  const MaterialModalActionSheetConfiguration({
    this.initialChildSize = 0.5,
    this.minChildSize = 0.25,
    this.maxChildSize = 0.9,
  });
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
}
