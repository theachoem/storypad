import 'package:super_editor/super_editor.dart';
import 'package:flutter/material.dart';

import '../../../document/selected_text.dart';
import 'desktop_context_menu_action.dart';
import 'desktop_context_menu_request.dart';
import 'desktop_context_menu.dart';
import '../story_context_menu_action.dart';

/// Adds a right-click context menu around [child], for desktop/web, where super_editor shows no selection menu of
/// its own. Right-clicking outside the selection first moves the caret there, like native text editors.
class DesktopContextMenuRegion extends StatelessWidget {
  const DesktopContextMenuRegion({
    super.key,
    required this.document,
    required this.composer,
    required this.editorOps,
    required this.documentLayoutResolver,
    required this.showMenu,
    required this.child,
    this.readOnly = false,
    this.extraActions = const [],
  });

  /// In read-only mode, Cut and Paste are ignored (and the default menu disables them).
  final bool readOnly;

  /// The app's extra items (`RawEditor.contextMenuActions`); only those shown in the current state are offered.
  final List<StoryContextMenuAction> extraActions;

  final Document document;
  final DocumentComposer composer;
  final CommonEditorOperations editorOps;
  final DocumentLayout Function() documentLayoutResolver;
  final DesktopContextMenuHandler showMenu;
  final Widget child;

  Future<void> _handleSecondaryTapUp(BuildContext context, TapUpDetails details) async {
    final layout = documentLayoutResolver();
    final position = layout.getDocumentPositionNearestToOffset(
      layout.getDocumentOffsetFromAncestorOffset(details.globalPosition),
    );
    if (position == null) return;

    final selection = composer.selection;
    if (selection == null || !selection.containsPosition(document, position)) {
      editorOps.insertCaretAtPosition(position);
    }

    final current = composer.selection;
    final hasSelection = current != null && !current.isCollapsed;
    final action = await showMenu(
      DesktopContextMenuRequest(
        context: context,
        globalPosition: details.globalPosition,
        hasSelection: hasSelection,
        selectedText: hasSelection ? SelectedText.plainText(document: document, selection: current) : '',
        readOnly: readOnly,
        extraActions: [
          for (final action in extraActions)
            if (action.isShown(readOnly: readOnly, hasSelection: hasSelection)) action,
        ],
      ),
    );

    switch (action) {
      case DesktopContextMenuAction.cut when !readOnly:
        editorOps.cut();
      case DesktopContextMenuAction.copy:
        editorOps.copy();
      case DesktopContextMenuAction.paste when !readOnly:
        editorOps.paste();
      case DesktopContextMenuAction.selectAll:
        editorOps.selectAll();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onSecondaryTapUp: (details) => _handleSecondaryTapUp(context, details), child: child);
  }
}
