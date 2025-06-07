import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';

/// Show OK alert dialog, whose appearance is adaptive according to platform
///
/// This is convenient wrapper of [showAlertDialog].
/// [barrierDismissible] (default: true) only works for material style,
/// and if it is set to false, pressing OK button is only way to close alert.
/// [actionsOverflowDirection] works only for Material style currently.
Future<OkCancelResult> showOkAlertDialog({
  required BuildContext context,
  String? title,
  String? message,
  String? okLabel,
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
  final isMacOS = adaptiveStyle.effectiveStyle(theme) == AdaptiveStyle.macOS;
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
        label: okLabel ?? MaterialLocalizations.of(context).okButtonLabel,
        key: OkCancelResult.ok,
        isDefaultAction: isMacOS,
      ),
    ],
  );
  return result ?? OkCancelResult.cancel;
}
