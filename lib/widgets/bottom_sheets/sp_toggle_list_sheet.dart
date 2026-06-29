import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

/// A toggleable row: the [value] it controls and its display [label].
typedef SpToggleItem<T> = ({T value, String label});

/// Multi-toggle list sheet with a Reset action at the bottom, applied in real
/// time. Decoupled from any view model — pass plain items + callbacks, and an
/// optional [listenable] (e.g. a ChangeNotifier) so the switches reflect
/// external state changes live.
///
/// ```
/// SpToggleListSheet<MySection>(
///   items: [for (final s in sections) (value: s, label: s.label)],
///   isEnabled: vm.isVisible,
///   onToggle: vm.toggle,
///   onReset: vm.reset,
///   listenable: vm,
/// ).show(context: context);
/// ```
class SpToggleListSheet<T> extends BaseBottomSheet {
  const SpToggleListSheet({
    required this.items,
    required this.isEnabled,
    required this.onToggle,
    required this.onReset,
    required this.listenable,
  });

  final List<SpToggleItem<T>> items;
  final bool Function(T value) isEnabled;
  final void Function(T value) onToggle;
  final VoidCallback onReset;

  // Can be a view model (ChangeNotifier)
  final Listenable listenable;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => _buildContent(context, bottomPadding),
    );
  }

  Widget _buildContent(BuildContext context, double bottomPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: .center,
        mainAxisSize: .min,
        children: [
          for (final item in items)
            SwitchListTile.adaptive(
              value: isEnabled(item.value),
              onChanged: (_) => onToggle(item.value),
              title: Text(item.label),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: OutlinedButton(onPressed: onReset, child: Text(tr('button.reset'))),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
