import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// A [PopupMenuButton] that holds the editor's selection while its menu is open. Opening the menu takes focus from
/// the editor, and on mobile the editor drops its selection on focus loss -- so without the hold, the chosen action
/// would find nothing selected.
class HeldPopupMenuButton<T> extends StatefulWidget {
  const HeldPopupMenuButton({
    super.key,
    required this.controller,
    required this.tooltip,
    required this.icon,
    required this.itemBuilder,
    required this.onSelected,
    this.enabled = true,
  });

  final StoryEditorController controller;
  final String tooltip;
  final Widget icon;
  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  State<HeldPopupMenuButton<T>> createState() => _HeldPopupMenuButtonState<T>();
}

class _HeldPopupMenuButtonState<T> extends State<HeldPopupMenuButton<T>> {
  SelectionHold? _hold;

  void _release() {
    _hold?.release();
    _hold = null;
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: widget.tooltip,
      icon: widget.icon,
      enabled: widget.enabled,
      onOpened: () => _hold = widget.controller.holdSelection(),
      onSelected: (value) {
        // Act first, while the selection is still held.
        widget.onSelected(value);
        _release();
      },
      onCanceled: _release,
      itemBuilder: widget.itemBuilder,
    );
  }
}
