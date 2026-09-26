import 'dart:ui' show Color, TextAlign;

import 'package:super_editor/super_editor.dart';

import '../markdown/markdown_format.dart';
import 'story_editor_controller.dart';

/// Formatting and block commands on the current selection, plus the state a toolbar shows for them. Headless: no
/// widgets or layout involved, so every action is unit-testable, and any toolbar (the app's, or the example's) is just
/// buttons calling these.
///
/// Reach it through [StoryEditorController.actions]; listen to the controller to rebuild when the selection,
/// document or pending styles change.
///
/// With a collapsed caret, inline toggles (bold, color, …) apply to the text typed next. Block commands apply to every
/// block the selection touches.
class StoryEditorActions {
  StoryEditorActions(this._controller);

  final StoryEditorController _controller;

  Editor get _editor => _controller.editor;
  MutableDocumentComposer get _composer => _controller.composer;
  Document get _document => _controller.document;
  DocumentSelection? get _selection => _composer.selection;

  // ── Selection ──────────────────────────────────────────────────────────────

  /// Whether some text is selected (an expanded selection, not just a caret).
  bool get hasSelection => _selection != null && !_selection!.isCollapsed;

  /// Every text block the selection touches, in document order.
  List<TextNode> get selectedTextNodes {
    final selection = _selection;
    if (selection == null) return const [];
    return _document.getNodesInside(selection.base, selection.extent).whereType<TextNode>().toList();
  }

  /// The selected text ranges `[start, end)` within each touched text block (empty for a collapsed caret).
  List<({TextNode node, int start, int end})> get _selectedRanges {
    final selection = _selection;
    if (selection == null || selection.isCollapsed) return const [];

    final normalized = selection.normalize(_document);
    final ranges = <({TextNode node, int start, int end})>[];
    for (final node in selectedTextNodes) {
      final start = node.id == normalized.start.nodeId ? _offset(normalized.start.nodePosition) ?? 0 : 0;
      final end = node.id == normalized.end.nodeId
          ? _offset(normalized.end.nodePosition) ?? node.text.length
          : node.text.length;
      if (end > start) ranges.add((node: node, start: start, end: end));
    }
    return ranges;
  }

  static int? _offset(NodePosition position) => position is TextNodePosition ? position.offset : null;

  // ── Inline formatting ──────────────────────────────────────────────────────

  bool get isBold => hasAttribution(boldAttribution);
  bool get isItalic => hasAttribution(italicsAttribution);
  bool get isUnderline => hasAttribution(underlineAttribution);
  bool get isStrikethrough => hasAttribution(strikethroughAttribution);
  bool get isInlineCode => hasAttribution(codeAttribution);
  bool get isSuperscript => hasAttribution(const ScriptAttribution.superscript());
  bool get isSubscript => hasAttribution(const ScriptAttribution.subscript());

  void toggleBold() => toggleAttribution(boldAttribution);
  void toggleItalic() => toggleAttribution(italicsAttribution);
  void toggleUnderline() => toggleAttribution(underlineAttribution);
  void toggleStrikethrough() => toggleAttribution(strikethroughAttribution);
  void toggleInlineCode() => toggleAttribution(codeAttribution);
  void toggleSuperscript() => _toggleScript(const ScriptAttribution.superscript());
  void toggleSubscript() => _toggleScript(const ScriptAttribution.subscript());

  /// Whether [attribution] applies throughout the selection -- or, for a caret, to the text typed next.
  bool hasAttribution(Attribution attribution) {
    final selection = _selection;
    if (selection == null) return false;
    if (selection.isCollapsed) return _composer.preferences.currentAttributions.contains(attribution);

    final ranges = _selectedRanges;
    return ranges.isNotEmpty &&
        ranges.every(
          (range) => range.node.text.hasAttributionsThroughout(
            attributions: {attribution},
            range: SpanRange(range.start, range.end - 1),
          ),
        );
  }

  /// Toggles [attribution] on the selection -- or, for a caret, on the text typed next.
  void toggleAttribution(Attribution attribution) {
    final selection = _selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      _composer.preferences.toggleStyles({attribution});
    } else {
      _editor.execute([
        ToggleTextAttributionsRequest(documentRange: selection, attributions: {attribution}),
      ]);
    }
  }

  /// Superscript and subscript are mutually exclusive (they conflict), so the other one is cleared first.
  void _toggleScript(ScriptAttribution script) {
    final other = script.type == ScriptAttribution.typeSuper
        ? const ScriptAttribution.subscript()
        : const ScriptAttribution.superscript();
    _removeAttributions({other});
    toggleAttribution(script);
  }

  /// The text color throughout the selection, or `null` if none or mixed.
  Color? get textColor => _uniform<ColorAttribution>()?.color;

  /// The highlight color throughout the selection, or `null` if none or mixed.
  Color? get backgroundColor => _uniform<BackgroundColorAttribution>()?.color;

  /// Sets the text color of the selection (or of the text typed next); `null` removes it.
  void setTextColor(Color? color) => _setValued<ColorAttribution>(color == null ? null : ColorAttribution(color));

  /// Sets the highlight color of the selection (or of the text typed next); `null` removes it.
  void setBackgroundColor(Color? color) =>
      _setValued<BackgroundColorAttribution>(color == null ? null : BackgroundColorAttribution(color));

  /// The link URL throughout the selection, or `null` if it isn't (uniformly) linked -- e.g. to pre-fill a link
  /// dialog.
  String? get linkUrl => _uniform<LinkAttribution>()?.plainTextUri;

  /// Links the selection to [url], replacing any link already there. No-op for a caret.
  void setLink(String url) {
    if (!hasSelection) return;
    _setValued<LinkAttribution>(LinkAttribution(url, Uri.tryParse(url)));
  }

  /// Removes links from the selection.
  void removeLink() => _setValued<LinkAttribution>(null);

  /// Removes all inline formatting (and links) from the selection -- or, for a caret, from the text typed next.
  void clearFormatting() {
    final selection = _selection;
    if (selection == null) return;
    if (selection.isCollapsed) {
      _composer.preferences.clearStyles();
      return;
    }
    final attributions = _attributionsInSelection((_) => true);
    if (attributions.isNotEmpty) {
      _editor.execute([RemoveTextAttributionsRequest(documentRange: selection, attributions: attributions)]);
    }
  }

  /// Replaces any [A] attribution in the selection (or pending for the caret) with [attribution], or just removes
  /// them when it's `null`. Valued attributions (colors, links) of the same kind conflict, so the old one must go
  /// first.
  void _setValued<A extends Attribution>(A? attribution) {
    final selection = _selection;
    if (selection == null) return;

    if (selection.isCollapsed) {
      _composer.preferences.removeStyles(_composer.preferences.currentAttributions.whereType<A>().toSet());
      if (attribution != null) _composer.preferences.addStyle(attribution);
      return;
    }

    _removeAttributions(_attributionsInSelection((a) => a is A));
    if (attribution != null) {
      _editor.execute([
        AddTextAttributionsRequest(documentRange: selection, attributions: {attribution}),
      ]);
    }
  }

  void _removeAttributions(Set<Attribution> attributions) {
    final selection = _selection;
    if (selection == null || attributions.isEmpty) return;
    if (selection.isCollapsed) {
      _composer.preferences.removeStyles(attributions);
    } else {
      _editor.execute([RemoveTextAttributionsRequest(documentRange: selection, attributions: attributions)]);
    }
  }

  Set<Attribution> _attributionsInSelection(bool Function(Attribution) filter) => {
    for (final range in _selectedRanges)
      ...range.node.text
          .getAttributionSpansInRange(attributionFilter: filter, range: SpanRange(range.start, range.end - 1))
          .map((span) => span.attribution),
  };

  /// The one [A] attribution covering the whole selection (or pending for the caret), if there is exactly one.
  A? _uniform<A extends Attribution>() {
    final selection = _selection;
    if (selection == null) return null;
    if (selection.isCollapsed) return _composer.preferences.currentAttributions.whereType<A>().firstOrNull;

    final found = _attributionsInSelection((a) => a is A);
    if (found.length != 1) return null;
    final attribution = found.single as A;
    return hasAttribution(attribution) ? attribution : null;
  }

  // ── Blocks ─────────────────────────────────────────────────────────────────

  /// The block type of the block under the caret/selection extent: [paragraphAttribution], `header1`…`header6`,
  /// [blockquoteAttribution] or [codeAttribution]. List items and tasks report [paragraphAttribution].
  Attribution get blockType {
    final node = selectedTextNodes.lastOrNull;
    if (node is! ParagraphNode) return paragraphAttribution;
    return node.getMetadataValue(NodeMetadata.blockType) ?? paragraphAttribution;
  }

  /// The heading level (1–6) of the block under the selection extent, or `null` if it isn't a heading.
  int? get headingLevel => headerLevel(blockType);

  /// Makes every selected block a heading of [level] (1–6), or a plain paragraph for `null`.
  void setHeading(int? level) => _setBlockType(level == null ? paragraphAttribution : headerAttribution(level));

  bool get isBlockquote => _allHaveBlockType(blockquoteAttribution);
  bool get isCodeBlock => _allHaveBlockType(codeAttribution);

  void toggleBlockquote() => _toggleBlockType(blockquoteAttribution);
  void toggleCodeBlock() => _toggleBlockType(codeAttribution);

  bool _allHaveBlockType(Attribution blockType) {
    final nodes = selectedTextNodes;
    return nodes.isNotEmpty &&
        nodes.every((node) => node is ParagraphNode && node.getMetadataValue(NodeMetadata.blockType) == blockType);
  }

  void _toggleBlockType(Attribution blockType) =>
      _setBlockType(_allHaveBlockType(blockType) ? paragraphAttribution : blockType);

  void _setBlockType(Attribution blockType) {
    final nodes = selectedTextNodes;
    if (nodes.isEmpty) return;
    _editor.execute([
      for (final node in nodes)
        if (node is ParagraphNode)
          ChangeParagraphBlockTypeRequest(nodeId: node.id, blockType: blockType)
        else
          ReplaceNodeRequest(
            existingNodeId: node.id,
            newNode: ParagraphNode(
              id: node.id,
              text: node.text,
              indent: _indentOf(node),
              metadata: {NodeMetadata.blockType: blockType},
            ),
          ),
    ]);
  }

  bool get isBulletList => _allListItems(ListItemType.unordered);
  bool get isOrderedList => _allListItems(ListItemType.ordered);
  bool get isTaskList {
    final nodes = selectedTextNodes;
    return nodes.isNotEmpty && nodes.every((node) => node is TaskNode);
  }

  void toggleBulletList() => _toggleList(ListItemType.unordered);
  void toggleOrderedList() => _toggleList(ListItemType.ordered);

  bool _allListItems(ListItemType type) {
    final nodes = selectedTextNodes;
    return nodes.isNotEmpty && nodes.every((node) => node is ListItemNode && node.type == type);
  }

  /// Converts every selected block to a [type] list item, or back to paragraphs if they all already are. Indent is
  /// kept across the conversion.
  void _toggleList(ListItemType type) {
    final nodes = selectedTextNodes;
    if (nodes.isEmpty) return;
    final active = _allListItems(type);
    _replaceAll(
      nodes,
      (node) => active
          ? ParagraphNode(id: node.id, text: node.text, indent: _indentOf(node))
          : ListItemNode(id: node.id, itemType: type, text: node.text, indent: _indentOf(node)),
    );
  }

  /// Converts every selected block to an unchecked task, or back to paragraphs if they all already are tasks.
  void toggleTaskList() {
    final nodes = selectedTextNodes;
    if (nodes.isEmpty) return;
    final active = isTaskList;
    _replaceAll(
      nodes,
      (node) => active
          ? ParagraphNode(id: node.id, text: node.text, indent: _indentOf(node))
          : TaskNode(id: node.id, text: node.text, isComplete: false, indent: _indentOf(node)),
    );
  }

  void _replaceAll(List<TextNode> nodes, DocumentNode Function(TextNode node) replacement) {
    _editor.execute([
      for (final node in nodes) ReplaceNodeRequest(existingNodeId: node.id, newNode: replacement(node)),
    ]);
  }

  static int _indentOf(TextNode node) => switch (node) {
    ListItemNode() => node.indent,
    TaskNode() => node.indent,
    ParagraphNode() => node.indent,
    _ => 0,
  };

  /// Whether any selected block can be indented further (up to 6 levels).
  bool get canIndent => selectedTextNodes.any((node) => _indentOf(node) < maxIndent);

  /// Whether any selected block is indented.
  bool get canOutdent => selectedTextNodes.any((node) => _indentOf(node) > 0);

  /// Indents every selected block one level. Tasks indent freely, even without a parent task above (super_editor's
  /// own task indent refuses that).
  void indent() {
    final requests = <EditRequest>[
      for (final node in selectedTextNodes)
        if (_indentOf(node) < maxIndent)
          switch (node) {
            ListItemNode() => IndentListItemRequest(nodeId: node.id),
            TaskNode() => SetTaskIndentRequest(node.id, node.indent + 1),
            _ => IndentParagraphRequest(node.id),
          },
    ];
    if (requests.isNotEmpty) _editor.execute(requests);
  }

  /// Outdents every selected block one level.
  void outdent() {
    final requests = <EditRequest>[
      for (final node in selectedTextNodes)
        if (_indentOf(node) > 0)
          switch (node) {
            ListItemNode() => UnIndentListItemRequest(nodeId: node.id),
            TaskNode() => SetTaskIndentRequest(node.id, node.indent - 1),
            _ => UnIndentParagraphRequest(node.id),
          },
    ];
    if (requests.isNotEmpty) _editor.execute(requests);
  }

  /// The alignment of the block under the selection extent.
  TextAlign get alignment {
    return switch (selectedTextNodes.lastOrNull?.getMetadataValue(TextNodeMetadata.textAlign)) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => TextAlign.left,
    };
  }

  /// Aligns every selected paragraph, heading and quote. List items, tasks and code blocks have no alignment.
  void setAlignment(TextAlign alignment) {
    final nodes = selectedTextNodes.whereType<ParagraphNode>().where(
      (node) => node.getMetadataValue(NodeMetadata.blockType) != codeAttribution,
    );
    if (nodes.isEmpty) return;
    _editor.execute([for (final node in nodes) ChangeParagraphAlignmentRequest(nodeId: node.id, alignment: alignment)]);
  }

  /// Inserts a horizontal rule at the caret (splitting the paragraph if needed).
  void insertHorizontalRule() {
    final selection = _selection;
    if (selection == null) return;
    _editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(position: selection.extent),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      InsertNodeAtCaretRequest(node: HorizontalRuleNode(id: Editor.createNodeId())),
    ]);
  }

  // ── History ────────────────────────────────────────────────────────────────

  bool get canUndo => _editor.history.isNotEmpty;
  bool get canRedo => _editor.future.isNotEmpty;

  void undo() {
    if (canUndo) _editor.undo();
  }

  void redo() {
    if (canRedo) _editor.redo();
  }
}
