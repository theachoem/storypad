// ignore_for_file: depend_on_referenced_packages

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_dialog/src/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Show OK/Cancel alert dialog, whose appearance is adaptive according to platform
///
/// This is convenient wrapper of [showAlertDialog].
/// [barrierDismissible] (default: true) only works for material style,
/// and if it is set to false, pressing OK or Cancel buttons is only way to
/// close alert.
/// [defaultType] only works for cupertino style and if it is specified
/// OK or Cancel button label will be changed to bold.
/// [actionsOverflowDirection] works only for Material style currently.
@useResult
Future<OkCancelResult> showOkCancelAlertDialog({
  required BuildContext context,
  String? title,
  String? message,
  String? okLabel,
  String? cancelLabel,
  OkCancelAlertDefaultType? defaultType,
  bool isDestructiveAction = false,
  bool barrierDismissible = true,
  @Deprecated('Use `style` instead.') AdaptiveStyle? alertStyle,
  AdaptiveStyle? style,
  @Deprecated('Use `ios` instead. Will be removed in v2.')
  bool useActionSheetForCupertino = false,
  bool useActionSheetForIOS = false,
  bool useRootNavigator = true,
  VerticalDirection actionsOverflowDirection = VerticalDirection.up,
  bool fullyCapitalizedForMaterial = true,
  bool canPop = true,
  PopInvokedWithResultCallback<OkCancelResult>? onPopInvokedWithResult,
  AdaptiveDialogBuilder? builder,
  RouteSettings? routeSettings,
}) async {
  final theme = Theme.of(context);
  final adaptiveStyle = style ?? AdaptiveDialog.instance.defaultStyle;
  final isMaterial = adaptiveStyle.isMaterial(theme);
  String defaultCancelLabel() {
    final label = MaterialLocalizations.of(context).cancelButtonLabel;
    return isMaterial ? label : label.capitalizedForce;
  }

  final result = await showAlertDialog<OkCancelResult>(
    routeSettings: routeSettings,
    context: context,
    title: title,
    message: message,
    barrierDismissible: barrierDismissible,
    style: alertStyle ?? style,
    useActionSheetForIOS: useActionSheetForCupertino || useActionSheetForIOS,
    useRootNavigator: useRootNavigator,
    actionsOverflowDirection: actionsOverflowDirection,
    fullyCapitalizedForMaterial: fullyCapitalizedForMaterial,
    canPop: canPop,
    onPopInvokedWithResult: onPopInvokedWithResult,
    builder: builder,
    actions: [
      AlertDialogAction(
        label: cancelLabel ?? defaultCancelLabel(),
        key: OkCancelResult.cancel,
        isDefaultAction: defaultType == OkCancelAlertDefaultType.cancel,
      ),
      AlertDialogAction(
        label: okLabel ?? MaterialLocalizations.of(context).okButtonLabel,
        key: OkCancelResult.ok,
        isDefaultAction:
            defaultType == null || defaultType == OkCancelAlertDefaultType.ok,
        isDestructiveAction: isDestructiveAction,
      ),
    ],
  );
  return result ?? OkCancelResult.cancel;
}
