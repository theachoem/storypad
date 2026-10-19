import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../reader_menu.dart';
import 'story_process_text.dart';
import 'vendor/android_popover_toolbar.dart';

/// The Android read-only toolbar, with the editing toolbar's look: Copy, Select All, the OS's "Process Text" actions
/// (Translate, …; given the text, never replacing it), then the app's extra items. super_editor positions it.
class StoryAndroidReaderToolbar extends StatelessWidget {
  const StoryAndroidReaderToolbar({
    super.key,
    required this.menu,
    required this.processTextActions,
    this.selectionRect,
  });

  final ReaderMenu menu;
  final List<ProcessTextAction> processTextActions;

  /// The selection's global rect, for the toolbar to tell which side of it the reader put it on (see
  /// `AndroidPopoverToolbar.anchorRect`).
  final ValueGetter<Rect?>? selectionRect;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Theme(
      data: ThemeData(
        colorScheme: brightness == Brightness.light
            ? const ColorScheme.light(primary: Colors.black)
            : const ColorScheme.dark(primary: Colors.white),
      ),
      child: ValueListenableBuilder<DocumentSelection?>(
        valueListenable: menu.composer.selectionNotifier,
        builder: (context, selection, _) {
          final localizations = MaterialLocalizations.of(context);
          final buttons = <(String, VoidCallback)>[
            if (menu.hasSelection)
              (
                localizations.copyButtonLabel,
                () {
                  menu.copy();
                  // As a read-only Android text view does: copied, the selection (and with it the toolbar) goes.
                  menu.composer.clearSelection();
                },
              ),
            (localizations.selectAllButtonLabel, menu.selectAll),
            if (menu.hasSelection)
              for (final action in processTextActions)
                (
                  action.label,
                  () {
                    final text = menu.selectedText;
                    menu.composer.clearSelection();
                    StoryProcessText.processTextAction(action.id, text, true);
                  },
                ),
            for (final action in menu.shownExtraActions)
              (
                action.label,
                () {
                  menu.composer.clearSelection();
                  action.onPressed();
                },
              ),
          ];

          return ConstrainedBox(
            // As narrow as the editing toolbar (and native Android's): a few items, then ⋮.
            constraints: const BoxConstraints(maxWidth: 280),
            child: AndroidPopoverToolbar(
              isAbove: true,
              anchorRect: selectionRect,
              // The reader's ToolbarPositionDelegate: 24 from the selection, and above only with another 24 to spare.
              gapAbove: 48,
              gapBelow: 24,
              toolbarBuilder: (context, child) => AndroidPopoverToolbarContainer(child: child),
              children: [
                for (final (index, (label, onPressed)) in buttons.indexed)
                  TextSelectionToolbarTextButton(
                    padding: TextSelectionToolbarTextButton.getPadding(index, buttons.length),
                    onPressed: onPressed,
                    alignment: AlignmentDirectional.center,
                    child: Text(label),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
