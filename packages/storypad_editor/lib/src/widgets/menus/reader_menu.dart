import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import 'story_context_menu_action.dart';
import '../../document/selected_text.dart';

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
    return SelectedText.plainText(document: document, selection: selection);
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
