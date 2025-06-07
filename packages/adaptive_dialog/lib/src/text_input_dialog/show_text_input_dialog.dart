// ignore_for_file: depend_on_referenced_packages

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_dialog/src/text_input_dialog/ios_text_input_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'material_text_input_dialog.dart';

@useResult
Future<List<String>?> showTextInputDialog({
  required BuildContext context,
  required List<DialogTextField> textFields,
  String? title,
  String? message,
  String? okLabel,
  String? cancelLabel,
  bool isDestructiveAction = false,
  bool barrierDismissible = true,
  AdaptiveStyle? style,
  bool useRootNavigator = true,
  VerticalDirection actionsOverflowDirection = VerticalDirection.up,
  bool fullyCapitalizedForMaterial = true,
  bool canPop = true,
  PopInvokedWithResultCallback<List<String>?>? onPopInvokedWithResult,
  bool autoSubmit = false,
  AdaptiveDialogBuilder? builder,
  RouteSettings? routeSettings,
}) {
  final theme = Theme.of(context);
  final adaptiveStyle = style ?? AdaptiveDialog.instance.defaultStyle;
  final effectiveStyle = adaptiveStyle.effectiveStyle(theme);
  switch (effectiveStyle) {
    // ignore: deprecated_member_use_from_same_package
    case AdaptiveStyle.cupertino:
    case AdaptiveStyle.iOS:
    case AdaptiveStyle.macOS:
      return showCupertinoDialog(
        context: context,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        builder: (context) {
          final dialog = IOSTextInputDialog(
            textFields: textFields,
            title: title,
            message: message,
            okLabel: okLabel,
            cancelLabel: cancelLabel,
            isDestructiveAction: isDestructiveAction,
            style: adaptiveStyle,
            useRootNavigator: useRootNavigator,
            canPop: canPop,
            onPopInvokedWithResult: onPopInvokedWithResult,
            autoSubmit: autoSubmit,
          );
          return builder == null ? dialog : builder(context, dialog);
        },
      );
    case AdaptiveStyle.material:
      return showDialog(
        context: context,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        barrierDismissible: barrierDismissible,
        builder: (context) {
          final dialog = MaterialTextInputDialog(
            textFields: textFields,
            title: title,
            message: message,
            okLabel: okLabel,
            cancelLabel: cancelLabel,
            isDestructiveAction: isDestructiveAction,
            style: adaptiveStyle,
            actionsOverflowDirection: actionsOverflowDirection,
            useRootNavigator: useRootNavigator,
            fullyCapitalized: fullyCapitalizedForMaterial,
            canPop: canPop,
            onPopInvokedWithResult: onPopInvokedWithResult,
            autoSubmit: autoSubmit,
          );
          return builder == null ? dialog : builder(context, dialog);
        },
      );
    case AdaptiveStyle.adaptive:
      assert(false);
      return Future.value();
  }
}

@immutable
class DialogTextField {
  const DialogTextField({
    this.initialText,
    this.hintText,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.suffixText,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.autocorrect = true,
    this.spellCheckConfiguration,
  });

  final String? initialText;
  final String? hintText;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final String? suffixText;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final bool autocorrect;
  final SpellCheckConfiguration? spellCheckConfiguration;
}
