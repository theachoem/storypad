import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';

import 'vendor/android_popover_toolbar.dart';
import '../story_context_menu_action.dart';
import '../../../document/selected_text.dart';
import 'story_process_text.dart';

/// SuperEditor's built-in Android toolbar (`DefaultAndroidEditorToolbar`) only offers
/// Cut/Copy/Paste/Select All — there's no extension point for extra buttons. This is a
/// copy of its implementation (`AndroidTextEditingFloatingToolbar`, in
/// `super_editor/lib/src/infrastructure/platforms/android/toolbar.dart`) with one
/// addition: a button for each Android "Process Text" action the OS reports — the same
/// mechanism that gives native `TextField`s their "Translate"/"Assist"/dictionary
/// entries (`Intent.ACTION_PROCESS_TEXT`, from the package's Android side: [StoryProcessText]).
/// Picking one launches that app's real activity with the selected text, and — if the
/// activity returns a transformed version — replaces the selection with it.
///
/// This widget is a pure "given this list, render buttons" component. It doesn't query
/// the actions itself — [processTextActions] comes from `RawEditor` (a long-lived
/// ancestor), which queries them up front and again as each selection starts, so the
/// list is fresh by the time the toolbar shows, with no loading state here.
///
/// Uses a vendored copy of `AndroidPopoverToolbar`/`AndroidPopoverToolbarContainer`
/// (see `vendor/android_popover_toolbar.dart`), an internal SuperEditor widget, so this
/// renders with the exact same pill/overflow chrome as SuperEditor's own Android toolbar.
class AndroidTextEditingFloatingToolbarWithProcessText extends StatefulWidget {
  const AndroidTextEditingFloatingToolbarWithProcessText({
    super.key,
    this.floatingToolbarKey,
    this.focalPoint,
    required this.document,
    required this.editorOps,
    required this.editorControlsController,
    required this.selectionNotifier,
    required this.processTextActions,
    this.extraActions = const [],
    this.selectionRect,
    required this.replaceSelection,
  });

  final Key? floatingToolbarKey;
  final LeaderLink? focalPoint;
  final Document document;
  final CommonEditorOperations editorOps;
  final SuperEditorAndroidControlsController editorControlsController;
  final ValueListenable<DocumentSelection?> selectionNotifier;
  final List<ProcessTextAction> processTextActions;

  /// The app's extra items (`RawEditor.contextMenuActions`), after the process-text ones.
  final List<StoryContextMenuAction> extraActions;

  /// The selection's global rect, for the toolbar to tell which side of it super_editor put it on (see
  /// `AndroidPopoverToolbar.anchorRect`).
  final ValueGetter<Rect?>? selectionRect;

  /// Replaces the selection with the text a process-text app returned.
  final ValueChanged<String> replaceSelection;

  @override
  State<AndroidTextEditingFloatingToolbarWithProcessText> createState() =>
      _AndroidTextEditingFloatingToolbarWithProcessTextState();

  // =============================================================================
  // Android: floating toolbar augmented with native "Process Text" actions.
  // =============================================================================

  /// The widest we let the Android floating toolbar grow before it must overflow
  /// extra buttons into the ⋮ menu — matching the comfortably-narrow width native
  /// Android's own selection toolbar uses, regardless of screen size, rather than
  /// stretching to fill all available width.
  static const _maxToolbarWidth = 280.0;

  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return AndroidPopoverToolbarContainer(child: child);
  }

  // =============================================================================
  // Shared helper: serialize a document selection to plain text.
  // =============================================================================
}

class _AndroidTextEditingFloatingToolbarWithProcessTextState
    extends State<AndroidTextEditingFloatingToolbarWithProcessText> {
  void _cut() {
    widget.editorOps.cut();
    widget.editorControlsController.hideToolbar();
  }

  void _copy() {
    widget.editorOps.copy();
    widget.editorControlsController.hideToolbar();
  }

  void _paste() {
    widget.editorOps.paste();
    widget.editorControlsController.hideToolbar();
  }

  void _selectAll() {
    widget.editorOps.selectAll();
  }

  Future<void> _runProcessTextAction(ProcessTextAction action) async {
    final selection = widget.selectionNotifier.value;
    if (selection == null || selection.isCollapsed) {
      return;
    }
    final selectedText = SelectedText.plainText(document: widget.document, selection: selection);
    if (selectedText.isEmpty) {
      return;
    }

    widget.editorControlsController.hideToolbar();

    final processedText = await StoryProcessText.processTextAction(action.id, selectedText, false);

    // Some actions (e.g. "Assist"-style lookups) never return a transformed version of
    // the text — they just do something with it externally. Only actions that hand
    // back a replacement (e.g. Translate) should change the document.
    if (processedText == null) {
      return;
    }

    widget.replaceSelection(processedText);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Theme(
      data: ThemeData(
        colorScheme: brightness == Brightness.light
            ? const ColorScheme.light(primary: Colors.black)
            : const ColorScheme.dark(primary: Colors.white),
      ),
      child: KeyedSubtree(
        key: widget.floatingToolbarKey,
        child: ValueListenableBuilder<DocumentSelection?>(
          valueListenable: widget.selectionNotifier,
          builder: (context, selection, child) {
            // Matches DefaultAndroidEditorToolbar's own (slightly unusual) rule for
            // when Cut/Copy are enabled: also true while selection is transiently null.
            final hasExpandedSelection = selection == null || !selection.isCollapsed;
            // Process-text actions need actual selected text to send, so — unlike
            // Cut/Copy above — a null selection doesn't count.
            final hasSelectedText = selection != null && !selection.isCollapsed;
            final processTextActions = hasSelectedText ? widget.processTextActions : const <ProcessTextAction>[];

            // The app's language, like Flutter's own text selection toolbar.
            final localizations = MaterialLocalizations.of(context);
            final buttons = <_ButtonViewModel>[
              if (hasExpandedSelection) _ButtonViewModel(onPressed: _cut, title: localizations.cutButtonLabel),
              if (hasExpandedSelection) _ButtonViewModel(onPressed: _copy, title: localizations.copyButtonLabel),
              _ButtonViewModel(onPressed: _paste, title: localizations.pasteButtonLabel),
              _ButtonViewModel(onPressed: _selectAll, title: localizations.selectAllButtonLabel),
              for (final action in processTextActions)
                _ButtonViewModel(onPressed: () => _runProcessTextAction(action), title: action.label),
              for (final action in widget.extraActions)
                if (action.isShown(readOnly: false, hasSelection: hasSelectedText))
                  _ButtonViewModel(
                    onPressed: () {
                      widget.editorControlsController.hideToolbar();
                      action.onPressed();
                    },
                    title: action.label,
                  ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                // AndroidPopoverToolbar only overflows buttons into the ⋮ menu once
                // they don't fit within the width it's given — and by default that's
                // the *entire* available width (from ScreenFollowerBoundary), which
                // lets far more short-labeled buttons fit on one row than native
                // Android's own toolbar would ever show before overflowing. Native
                // caps out at a comfortably narrow width regardless of screen size,
                // so we do too, forcing the same "a few items, then ⋮" appearance.
                final maxWidth =
                    constraints.maxWidth < AndroidTextEditingFloatingToolbarWithProcessText._maxToolbarWidth
                    ? constraints.maxWidth
                    : AndroidTextEditingFloatingToolbarWithProcessText._maxToolbarWidth;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AndroidPopoverToolbar(
                    // Its side found from the selection (and re-checked as the focal point moves).
                    isAbove: true,
                    anchorRect: widget.selectionRect,
                    anchorChanges: widget.focalPoint,
                    // super_editor's toolbar aligner: 20 above the selection, 90 below (clear of the handles).
                    gapAbove: 20,
                    gapBelow: 90,
                    toolbarBuilder: AndroidTextEditingFloatingToolbarWithProcessText._defaultToolbarBuilder,
                    children: [
                      for (int i = 0; i < buttons.length; i++)
                        TextSelectionToolbarTextButton(
                          padding: TextSelectionToolbarTextButton.getPadding(i, buttons.length),
                          onPressed: buttons[i].onPressed,
                          alignment: AlignmentDirectional.center,
                          child: Text(buttons[i].title),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ButtonViewModel {
  _ButtonViewModel({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;
}
