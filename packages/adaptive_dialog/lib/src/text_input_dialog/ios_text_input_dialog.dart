// ignore_for_file: depend_on_referenced_packages

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_dialog/src/extensions/extensions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IOSTextInputDialog extends StatefulWidget {
  const IOSTextInputDialog({
    super.key,
    required this.textFields,
    this.title,
    this.message,
    this.okLabel,
    this.cancelLabel,
    this.isDestructiveAction = false,
    this.style = AdaptiveStyle.adaptive,
    this.useRootNavigator = true,
    required this.canPop,
    required this.onPopInvokedWithResult,
    this.autoSubmit = false,
  });
  @override
  State<IOSTextInputDialog> createState() => _IOSTextInputDialogState();

  final List<DialogTextField> textFields;
  final String? title;
  final String? message;
  final String? okLabel;
  final String? cancelLabel;
  final bool isDestructiveAction;
  final AdaptiveStyle style;
  final bool useRootNavigator;
  final bool canPop;
  final PopInvokedWithResultCallback<List<String>?>? onPopInvokedWithResult;
  final bool autoSubmit;
}

class _IOSTextInputDialogState extends State<IOSTextInputDialog> {
  late final List<TextEditingController> _textControllers = widget.textFields
      .map((tf) => TextEditingController(text: tf.initialText))
      .toList();
  String? _validationMessage;
  bool _autovalidate = false;

  @override
  void initState() {
    super.initState();

    for (final c in _textControllers) {
      c.addListener(() {
        if (_autovalidate) {
          _validate();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(
      context,
      rootNavigator: widget.useRootNavigator,
    );
    final title = widget.title;
    final message = widget.message;
    void submit() => navigator.pop(
          _textControllers.map((c) => c.text).toList(),
        );
    void submitIfValid() {
      if (_validate()) {
        submit();
      }
    }

    void cancel() => navigator.pop();
    BoxDecoration borderDecoration({
      required bool isTopRounded,
      required bool isBottomRounded,
    }) {
      const radius = 6.0;
      const borderSide = BorderSide(
        color: CupertinoDynamicColor.withBrightness(
          color: Color(0x33000000),
          darkColor: Color(0x33FFFFFF),
        ),
        width: 0,
      );
      return BoxDecoration(
        color: const CupertinoDynamicColor.withBrightness(
          color: CupertinoColors.white,
          darkColor: CupertinoColors.black,
        ),
        border: const Border(
          top: borderSide,
          bottom: borderSide,
          left: borderSide,
          right: borderSide,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isTopRounded ? radius : 0),
          bottom: Radius.circular(isBottomRounded ? radius : 0),
        ),
      );
    }

    final validationMessage = _validationMessage;
    return PopScope(
      canPop: widget.canPop,
      onPopInvokedWithResult: widget.onPopInvokedWithResult,
      child: CupertinoAlertDialog(
        title: title == null ? null : Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (message != null) Text(message),
            const SizedBox(height: 22),
            ..._textControllers.mapIndexed(
              (i, c) {
                final isLast = widget.textFields.length == i + 1;
                final field = widget.textFields[i];
                final prefixText = field.prefixText;
                final suffixText = field.suffixText;
                return CupertinoTextField(
                  contextMenuBuilder: _contextMenuBuilder,
                  controller: c,
                  autofocus: i == 0,
                  placeholder: field.hintText,
                  obscureText: field.obscureText,
                  keyboardType: field.keyboardType,
                  textCapitalization: field.textCapitalization,
                  maxLength: field.maxLength,
                  minLines: field.minLines,
                  maxLines: field.maxLines,
                  autocorrect: field.autocorrect,
                  prefix: prefixText == null ? null : Text(prefixText),
                  suffix: suffixText == null ? null : Text(suffixText),
                  decoration: borderDecoration(
                    isTopRounded: i == 0,
                    isBottomRounded: i == _textControllers.length - 1,
                  ),
                  textInputAction: isLast ? null : TextInputAction.next,
                  onSubmitted: isLast && widget.autoSubmit
                      ? (_) => submitIfValid()
                      : null,
                  spellCheckConfiguration: field.spellCheckConfiguration,
                );
              },
            ),
            if (validationMessage != null)
              Container(
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsets.only(
                  top: 4,
                  left: 4,
                ),
                child: Text(
                  validationMessage,
                  style: TextStyle(
                    color: CupertinoColors.systemRed.resolveFrom(context),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: cancel,
            isDefaultAction: true,
            child: Text(
              widget.cancelLabel ??
                  MaterialLocalizations.of(context)
                      .cancelButtonLabel
                      .capitalizedForce,
            ),
          ),
          CupertinoDialogAction(
            onPressed: submitIfValid,
            child: Text(
              widget.okLabel ?? MaterialLocalizations.of(context).okButtonLabel,
              style: TextStyle(
                color: widget.isDestructiveAction
                    ? CupertinoColors.systemRed.resolveFrom(context)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validate() {
    _autovalidate = true;
    final validations = widget.textFields.mapIndexed((i, tf) {
      final validator = tf.validator;
      return validator == null ? null : validator(_textControllers[i].text);
    }).where((result) => result != null);
    setState(() {
      _validationMessage = validations.isEmpty ? null : validations.join('\n');
    });
    return validations.isEmpty;
  }
}

/// SystemContextMenu対応のcontextMenuBuilder
///
/// SystemContextMenuがサポートされている場合はそれを利用したネイティブUIで、
/// それ以外の時は無指定の時と同じ挙動
Widget _contextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) =>
    SystemContextMenu.isSupported(context)
        ? SystemContextMenu.editableText(
            editableTextState: editableTextState,
          )
        : AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          );
