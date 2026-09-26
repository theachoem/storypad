import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';
// ignore: implementation_imports
import 'package:super_editor/src/infrastructure/flutter/android_toolbar.dart';

// =============================================================================
// Android: floating toolbar augmented with native "Process Text" actions.
// =============================================================================

/// The widest we let the Android floating toolbar grow before it must overflow
/// extra buttons into the ⋮ menu — matching the comfortably-narrow width native
/// Android's own selection toolbar uses, regardless of screen size, rather than
/// stretching to fill all available width.
const _maxToolbarWidth = 280.0;

/// SuperEditor's built-in Android toolbar (`DefaultAndroidEditorToolbar`) only offers
/// Cut/Copy/Paste/Select All — there's no extension point for extra buttons. This is a
/// copy of its implementation (`AndroidTextEditingFloatingToolbar`, in
/// `super_editor/lib/src/infrastructure/platforms/android/toolbar.dart`) with one
/// addition: a button for each Android "Process Text" action the OS reports — the same
/// mechanism that gives native `TextField`s their "Translate"/"Assist"/dictionary
/// entries (`Intent.ACTION_PROCESS_TEXT`, exposed to Dart as
/// [DefaultProcessTextService]). Picking one launches that app's real activity with the
/// selected text, and — if the activity returns a transformed version — replaces the
/// selection with it.
///
/// This widget is a pure "given this list, render buttons" component. It doesn't query
/// [DefaultProcessTextService] itself — [processTextActions] is queried once by
/// `RawEditor` (a long-lived ancestor), exactly the way `EditableText` queries it once
/// from its own `initState` and later reads the resulting list when it's about to show
/// its toolbar, rather than a short-lived toolbar widget querying it right when it's
/// about to be shown. Querying this early (well before any selection/toolbar
/// interaction can happen) gives the query plenty of time to resolve before it's ever
/// needed, with no `FutureBuilder`/loading-state dance required in the toolbar itself.
///
/// This deep-imports `AndroidPopoverToolbar`/`AndroidPopoverToolbarContainer`, an
/// internal (non-exported) SuperEditor widget, so this renders with the exact same
/// pill/overflow chrome as SuperEditor's own Android toolbar. Because that's not part
/// of super_editor's public API, it could change (or move) on a future super_editor
/// upgrade without a deprecation notice.
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
  });

  final Key? floatingToolbarKey;
  final LeaderLink? focalPoint;
  final Document document;
  final CommonEditorOperations editorOps;
  final SuperEditorAndroidControlsController editorControlsController;
  final ValueListenable<DocumentSelection?> selectionNotifier;
  final List<ProcessTextAction> processTextActions;

  @override
  State<AndroidTextEditingFloatingToolbarWithProcessText> createState() =>
      _AndroidTextEditingFloatingToolbarWithProcessTextState();
}

class _AndroidTextEditingFloatingToolbarWithProcessTextState
    extends State<AndroidTextEditingFloatingToolbarWithProcessText> {
  /// Whether the toolbar is above or below the focal point.
  ///
  /// This is used to determine the position of the back button in the overflow menu.
  bool _isAbove = true;

  @override
  void initState() {
    super.initState();
    widget.focalPoint?.addListener(_onFocalPointChange);
  }

  @override
  void didUpdateWidget(AndroidTextEditingFloatingToolbarWithProcessText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focalPoint != widget.focalPoint) {
      oldWidget.focalPoint?.removeListener(_onFocalPointChange);
      widget.focalPoint?.addListener(_onFocalPointChange);
    }
  }

  @override
  void dispose() {
    widget.focalPoint?.removeListener(_onFocalPointChange);
    super.dispose();
  }

  void _onFocalPointChange() {
    final leader = widget.focalPoint?.leader;
    if (leader == null) {
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final leaderOffset = leader.offset;
    final followerOffset = box.localToGlobal(Offset.zero);
    final isAbove = followerOffset < leaderOffset;

    if (isAbove != _isAbove) {
      setState(() {
        _isAbove = isAbove;
      });
    }
  }

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
    final selectedText = plainTextInSelection(document: widget.document, selection: selection);
    if (selectedText.isEmpty) {
      return;
    }

    widget.editorControlsController.hideToolbar();

    final processedText = await DefaultProcessTextService().processTextAction(action.id, selectedText, false);

    // Some actions (e.g. "Assist"-style lookups) never return a transformed version of
    // the text — they just do something with it externally. Only actions that hand
    // back a replacement (e.g. Translate) should change the document.
    if (processedText == null) {
      return;
    }

    // `insertPlainText` is deprecated in favor of executing an
    // InsertPlainTextAtCaretRequest directly, but that requires the Editor instance,
    // which CommonEditorOperations only exposes as @protected. This is the only public
    // way to replace a selection with text from outside the super_editor package.
    // ignore: deprecated_member_use
    widget.editorOps.insertPlainText(processedText);
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

            final buttons = <_ButtonViewModel>[
              if (hasExpandedSelection) _ButtonViewModel(onPressed: _cut, title: 'Cut'),
              if (hasExpandedSelection) _ButtonViewModel(onPressed: _copy, title: 'Copy'),
              _ButtonViewModel(onPressed: _paste, title: 'Paste'),
              _ButtonViewModel(onPressed: _selectAll, title: 'Select All'),
              for (final action in processTextActions)
                _ButtonViewModel(onPressed: () => _runProcessTextAction(action), title: action.label),
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
                final maxWidth = constraints.maxWidth < _maxToolbarWidth ? constraints.maxWidth : _maxToolbarWidth;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AndroidPopoverToolbar(
                    isAbove: _isAbove,
                    toolbarBuilder: _defaultToolbarBuilder,
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

Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
  return AndroidPopoverToolbarContainer(child: child);
}

class _ButtonViewModel {
  _ButtonViewModel({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;
}

// =============================================================================
// Shared helper: serialize a document selection to plain text.
// =============================================================================

/// Serializes the content spanned by [selection] to plain text.
///
/// This mirrors `CommonEditorOperations`'s private `_textInSelection`, which
/// backs `copy()`/`cut()`. It's duplicated here (using only the same public
/// [Document]/[DocumentNode] APIs that method itself uses) because both the
/// native macOS Services menu and the Android Process Text actions need the
/// selected text up front, without going through the system clipboard — using
/// the clipboard would mean silently overwriting whatever the user last
/// copied, just from right-clicking or long-pressing.
String plainTextInSelection({required Document document, required DocumentSelection selection}) {
  final selectedNodes = document.getNodesInside(selection.base, selection.extent);

  final buffer = StringBuffer();
  for (int i = 0; i < selectedNodes.length; ++i) {
    final selectedNode = selectedNodes[i];
    final NodeSelection nodeSelection;

    if (i == 0) {
      // This is the first node and it may be partially selected.
      final baseSelectionPosition = selectedNode.id == selection.base.nodeId
          ? selection.base.nodePosition
          : selection.extent.nodePosition;

      final extentSelectionPosition = selectedNodes.length > 1
          ? selectedNode.endPosition
          : selection.extent.nodePosition;

      nodeSelection = selectedNode.computeSelection(base: baseSelectionPosition, extent: extentSelectionPosition);
    } else if (i == selectedNodes.length - 1) {
      // This is the last node and it may be partially selected.
      final nodePosition = selectedNode.id == selection.base.nodeId
          ? selection.base.nodePosition
          : selection.extent.nodePosition;

      nodeSelection = selectedNode.computeSelection(base: selectedNode.beginningPosition, extent: nodePosition);
    } else {
      // This node is fully selected. Copy the whole thing.
      nodeSelection = selectedNode.computeSelection(
        base: selectedNode.beginningPosition,
        extent: selectedNode.endPosition,
      );
    }

    final nodeContent = selectedNode.copyContent(nodeSelection);
    if (nodeContent != null) {
      buffer.write(nodeContent);
      if (i < selectedNodes.length - 1) {
        buffer.writeln();
      }
    }
  }

  return buffer.toString();
}
