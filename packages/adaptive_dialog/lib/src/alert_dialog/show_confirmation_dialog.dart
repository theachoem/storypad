// ignore_for_file: depend_on_referenced_packages
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Show [confirmation dialog](https://material.io/components/dialogs#confirmation-dialog),
/// whose appearance is adaptive according to platform
///
/// For Cupertino, fallback to ActionSheet.
///
/// If [shrinkWrap] is true, material dialog height is determined by the
/// contents. This argument defaults to `true`. If you know the content height
/// is taller than the height of screen, it is recommended to set to `false`
/// for performance optimization.
/// if [initialSelectedActionKey] is set, corresponding action is selected
/// initially. This works only for Android style.
/// [toggleable] option is only supported in material dialog.
/// When set to `false`, the selected action cannot be unselected by tapping.
/// The default value is `true`.
@useResult
Future<T?> showConfirmationDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  String? okLabel,
  String? cancelLabel,
  double? contentMaxHeight,
  List<AlertDialogAction<T>> actions = const [],
  T? initialSelectedActionKey,
  bool barrierDismissible = true,
  AdaptiveStyle? style,
  bool useRootNavigator = true,
  bool shrinkWrap = true,
  bool fullyCapitalizedForMaterial = true,
  bool canPop = true,
  PopInvokedWithResultCallback<T>? onPopInvokedWithResult,
  AdaptiveDialogBuilder? builder,
  RouteSettings? routeSettings,
  bool toggleable = true,
}) {
  void pop({required BuildContext context, required T? key}) => Navigator.of(
        context,
        rootNavigator: useRootNavigator,
      ).pop(key);

  final theme = Theme.of(context);
  final adaptiveStyle = style ?? AdaptiveDialog.instance.defaultStyle;
  return adaptiveStyle.isMaterial(theme)
      ? showDialog(
          context: context,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          barrierDismissible: barrierDismissible,
          builder: (context) {
            final dialog = _ConfirmationMaterialDialog(
              title: title,
              onSelect: (key) => pop(context: context, key: key),
              message: message,
              okLabel: okLabel,
              cancelLabel: cancelLabel,
              actions: actions,
              initialSelectedActionKey: initialSelectedActionKey,
              contentMaxHeight: contentMaxHeight,
              shrinkWrap: shrinkWrap,
              fullyCapitalized: fullyCapitalizedForMaterial,
              canPop: canPop,
              onPopInvokedWithResult: onPopInvokedWithResult,
              toggleable: toggleable,
            );
            return builder == null ? dialog : builder(context, dialog);
          },
        )
      : showModalActionSheet(
          context: context,
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          actions: actions.convertToSheetActions(),
          style: style,
          useRootNavigator: useRootNavigator,
          canPop: canPop,
          onPopInvokedWithResult: onPopInvokedWithResult,
          builder: builder,
          routeSettings: routeSettings,
        );
}

class _ConfirmationMaterialDialog<T> extends StatefulWidget {
  const _ConfirmationMaterialDialog({
    super.key,
    required this.title,
    required this.onSelect,
    @required this.message,
    @required this.okLabel,
    @required this.cancelLabel,
    required this.actions,
    @required this.initialSelectedActionKey,
    @required this.contentMaxHeight,
    required this.shrinkWrap,
    required this.fullyCapitalized,
    required this.canPop,
    required this.onPopInvokedWithResult,
    required this.toggleable,
  });

  final String title;
  final ValueChanged<T?> onSelect;
  final String? message;
  final String? okLabel;
  final String? cancelLabel;
  final List<AlertDialogAction<T>> actions;
  final T? initialSelectedActionKey;
  final double? contentMaxHeight;
  final bool shrinkWrap;
  final bool fullyCapitalized;
  final bool canPop;
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;
  final bool toggleable;

  @override
  _ConfirmationMaterialDialogState<T> createState() => _ConfirmationMaterialDialogState<T>();
}

class _ConfirmationMaterialDialogState<T> extends State<_ConfirmationMaterialDialog<T>> {
  T? _selectedKey;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _selectedKey = widget.initialSelectedActionKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelLabel = widget.cancelLabel;
    final okLabel = widget.okLabel;
    final message = widget.message;
    return PopScope(
      canPop: widget.canPop,
      onPopInvokedWithResult: widget.onPopInvokedWithResult,
      child: Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        message,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 0),
            Flexible(
              child: SizedBox(
                height: widget.contentMaxHeight,
                child: RadioGroup(
                  groupValue: _selectedKey,
                  onChanged: (value) {
                    setState(() {
                      _selectedKey = value;
                    });
                  },
                  child: ListView(
                    // This switches physics automatically, so if there is enough
                    // height, `NeverScrollableScrollPhysics` will be set.
                    controller: _scrollController,
                    shrinkWrap: widget.shrinkWrap,
                    children: widget.actions
                        .map(
                          (action) => RadioListTile<T>(
                            title: Text(action.label, style: action.textStyle),
                            value: action.key,
                            toggleable: widget.toggleable,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.all(4),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    child: Text(
                      (widget.fullyCapitalized ? cancelLabel?.toUpperCase() : cancelLabel) ??
                          MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                    onPressed: () => widget.onSelect(null),
                  ),
                  TextButton(
                    onPressed: _selectedKey == null ? null : () => widget.onSelect(_selectedKey),
                    child: Text(
                      (widget.fullyCapitalized ? okLabel?.toUpperCase() : okLabel) ??
                          MaterialLocalizations.of(context).okButtonLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
