import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';

import 'android_toolbar.dart' show plainTextInSelection;
import 'context_menu_action.dart';
import 'vendor/android_popover_toolbar.dart';
import 'process_text.dart';

// The selection menus while read-only, where super_editor's reader shows none on Android and only a bare "Copy" bubble
// on iOS. iOS's own menu can't be used here: it's bound to text input, and a read-only document has none -- so iOS
// gets Flutter's iOS-style menu, as a read-only `SelectableText` does.

/// What a read-only selection menu offers: Copy (with a selection), Select All, then the app's extra items shown
/// while read-only.
final class ReaderMenu {
  ReaderMenu({required this.document, required this.composer, required this.extraActions});

  final Document document;
  final MutableDocumentComposer composer;
  final List<StoryContextMenuAction> extraActions;

  bool get hasSelection => composer.selection?.isCollapsed == false;

  String get selectedText {
    final selection = composer.selection;
    if (selection == null || selection.isCollapsed) return '';
    return plainTextInSelection(document: document, selection: selection);
  }

  void copy() => Clipboard.setData(ClipboardData(text: selectedText));

  void selectAll() {
    if (document.isEmpty) return;
    composer.setSelectionWithReason(
      DocumentSelection(
        base: DocumentPosition(nodeId: document.first.id, nodePosition: document.first.beginningPosition),
        extent: DocumentPosition(nodeId: document.last.id, nodePosition: document.last.endPosition),
      ),
      SelectionReason.userInteraction,
    );
  }

  List<StoryContextMenuAction> get shownExtraActions => [
    for (final action in extraActions)
      if (action.isShown(readOnly: true, hasSelection: hasSelection)) action,
  ];
}

/// The iOS read-only menu: Flutter's iOS-style toolbar at the selection ([focalPoint]).
class StoryIosReaderToolbar extends StatelessWidget {
  const StoryIosReaderToolbar({
    super.key,
    required this.focalPoint,
    required this.menu,
    required this.controlsController,
  });

  final LeaderLink focalPoint;
  final ReaderMenu menu;
  final SuperReaderIosControlsController controlsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([focalPoint, menu.composer.selectionNotifier]),
      builder: (context, _) {
        final offset = focalPoint.offset;
        final size = focalPoint.leaderSize;
        if (offset == null || size == null) return const SizedBox.shrink();

        final localizations = CupertinoLocalizations.of(context);
        final buttons = <(String, VoidCallback)>[
          if (menu.hasSelection)
            (
              localizations.copyButtonLabel,
              () {
                menu.copy();
                controlsController.hideToolbar();
              },
            ),
          (localizations.selectAllButtonLabel, menu.selectAll),
          for (final action in menu.shownExtraActions)
            (
              action.label,
              () {
                controlsController.hideToolbar();
                action.onPressed();
              },
            ),
        ];

        final rect = offset & size;
        return CupertinoTextSelectionToolbar(
          anchorAbove: rect.topCenter,
          anchorBelow: rect.bottomCenter,
          children: [
            for (final (index, (label, onPressed)) in buttons.indexed)
              CupertinoTextSelectionToolbarButton.text(key: ValueKey(index), text: label, onPressed: onPressed),
          ],
        );
      },
    );
  }
}

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
