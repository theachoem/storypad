// ignore_for_file: depend_on_referenced_packages

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@useResult
Future<bool> showTextAnswerDialog({
  required BuildContext context,
  required String keyword,
  String? title,
  String? message,
  String? okLabel,
  String? cancelLabel,
  bool isDestructiveAction = false,
  bool barrierDismissible = true,
  String? hintText,
  String? retryTitle,
  String? retryMessage,
  String? retryOkLabel,
  String? retryCancelLabel,
  AdaptiveStyle? style,
  bool useRootNavigator = true,
  VerticalDirection actionsOverflowDirection = VerticalDirection.up,
  bool fullyCapitalizedForMaterial = true,
  bool canPop = true,
  PopInvokedWithResultCallback<List<String>?>? onPopInvokedWithResult,
  bool autoSubmit = false,
  bool isCaseSensitive = true,
  AdaptiveDialogBuilder? builder,
}) async {
  final adaptiveStyle = style ?? AdaptiveDialog.instance.defaultStyle;

  final texts = await showTextInputDialog(
    context: context,
    textFields: [
      DialogTextField(hintText: hintText),
    ],
    title: title,
    message: message,
    okLabel: okLabel,
    cancelLabel: cancelLabel,
    isDestructiveAction: isDestructiveAction,
    style: adaptiveStyle,
    actionsOverflowDirection: actionsOverflowDirection,
    fullyCapitalizedForMaterial: fullyCapitalizedForMaterial,
    canPop: canPop,
    onPopInvokedWithResult: onPopInvokedWithResult,
    autoSubmit: autoSubmit,
    builder: builder,
  );

  final text = texts == null ? null : texts[0];

  if (text == null) return false;
  if (!context.mounted) return false;

  if (isCaseSensitive
      ? text == keyword
      : text.toUpperCase() == keyword.toUpperCase()) {
    return true;
  }

  final result = await showOkCancelAlertDialog(
    context: context,
    title: retryTitle,
    message: retryMessage,
    okLabel: retryOkLabel,
    cancelLabel: retryCancelLabel,
    defaultType: OkCancelAlertDefaultType.ok,
    actionsOverflowDirection: actionsOverflowDirection,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    fullyCapitalizedForMaterial: fullyCapitalizedForMaterial,
    builder: builder,
  );

  if (!context.mounted) return false;

  return result == OkCancelResult.ok
      ? showTextAnswerDialog(
          context: context,
          keyword: keyword,
          title: title,
          message: message,
          okLabel: okLabel,
          cancelLabel: cancelLabel,
          isDestructiveAction: isDestructiveAction,
          barrierDismissible: barrierDismissible,
          hintText: hintText,
          retryTitle: retryTitle,
          retryMessage: retryMessage,
          retryOkLabel: retryOkLabel,
          retryCancelLabel: retryCancelLabel,
          style: style,
          useRootNavigator: useRootNavigator,
          actionsOverflowDirection: actionsOverflowDirection,
          fullyCapitalizedForMaterial: fullyCapitalizedForMaterial,
          canPop: canPop,
          onPopInvokedWithResult: onPopInvokedWithResult,
          autoSubmit: autoSubmit,
          builder: builder,
        )
      : Future.value(false);
}
