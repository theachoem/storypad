import 'package:super_editor/super_editor.dart';

/// Indent behaves as in most editors (Google Docs, Pages, Notes), the same with a hardware keyboard and an on-screen
/// one:
///
///  * Enter keeps the line's indent: a new list item, task or paragraph starts at the level of the one it came from.
///  * Enter on an empty indented list item or task moves it out one level; only at the outermost level does it leave
///    the list (super_editor's default leaves the list at once, from any level, and a new task always starts unindented).
///  * Backspace at the start of an indented list item, task or paragraph moves it out one level. A hardware key already
///    did, through super_editor's keyboard actions; an on-screen keyboard's backspace comes as a
///    [DeleteUpstreamAtBeginningOfNodeRequest], which turned the item into an unindented paragraph instead.
///  * Typing a Markdown shortcut (`- `, `1. `, `> `) on an indented line keeps its indent ([indentKeepingReactions]).
///
/// An empty indented *paragraph* keeps its indent on Enter, as in those editors (see `RawEditor`'s keyboard actions,
/// which leave out super_editor's `enterToUnIndentParagraph`).
EditCommand? newlineKeepingIndentHandler(Editor editor, EditRequest request) {
  if (request is! InsertNewlineAtCaretRequest) return null;

  final selection = editor.composer.selection;
  if (selection == null) return null;

  // Routed by the selection's base, as super_editor routes its own newline commands.
  final node = editor.document.getNodeById(selection.base.nodeId);
  if (node is! TaskNode && node is! ListItemNode) return null;

  return _InsertNewlineKeepingIndentCommand(request.newNodeId);
}

/// See [newlineKeepingIndentHandler].
EditCommand? outdentAtLineStartHandler(Editor editor, EditRequest request) {
  if (request is! DeleteUpstreamAtBeginningOfNodeRequest) return null;

  final node = editor.document.getNodeById(request.node.id);
  return switch (node) {
    ListItemNode(:final indent) when indent > 0 => UnIndentListItemCommand(nodeId: node.id),
    TaskNode(:final indent) when indent > 0 => SetTaskIndentCommand(node.id, indent - 1),
    ParagraphNode(:final indent) when indent > 0 && node.getMetadataValue(NodeMetadata.blockType) != codeAttribution =>
      UnIndentParagraphCommand(node.id),
    _ => null,
  };
}

/// super_editor's [defaultEditorReactions], with the Markdown shortcuts that turn a line into a list item or quote
/// keeping the line's indent (theirs start the block unindented). See [newlineKeepingIndentHandler].
Iterable<EditReaction> indentKeepingReactions(Iterable<EditReaction> reactions) {
  return reactions.map(
    (reaction) => switch (reaction) {
      UnorderedListItemConversionReaction() => const _UnorderedListShortcutKeepingIndent(),
      OrderedListItemConversionReaction() => const _OrderedListShortcutKeepingIndent(),
      BlockquoteConversionReaction() => const _BlockquoteShortcutKeepingIndent(),
      _ => reaction,
    },
  );
}

class _InsertNewlineKeepingIndentCommand extends BaseInsertNewlineAtCaretCommand {
  const _InsertNewlineKeepingIndentCommand(this.newNodeId);

  final String newNodeId;

  @override
  void doInsertNewline(
    EditContext context,
    CommandExecutor executor,
    DocumentPosition caretPosition,
    NodePosition caretNodePosition,
  ) {
    final node = context.document.getNodeById(caretPosition.nodeId);
    if (caretNodePosition is! TextNodePosition) {
      DefaultInsertNewlineAtCaretCommand(
        newNodeId,
      ).doInsertNewline(context, executor, caretPosition, caretNodePosition);
      return;
    }

    switch (node) {
      case TaskNode(:final indent) when node.text.isEmpty && indent > 0:
        executor.executeCommand(SetTaskIndentCommand(node.id, indent - 1));
      case TaskNode() when node.text.isNotEmpty:
        // The split moves the caret to the new task, which super_editor starts unindented.
        executor
          ..executeCommand(
            SplitExistingTaskCommand(nodeId: node.id, splitOffset: caretNodePosition.offset, newNodeId: newNodeId),
          )
          ..executeCommand(SetTaskIndentCommand(newNodeId, node.indent));
      case TaskNode():
        InsertNewlineInTaskAtCaretCommand(
          newNodeId,
        ).doInsertNewline(context, executor, caretPosition, caretNodePosition);
      case ListItemNode(:final indent) when node.text.isEmpty && indent > 0:
        executor.executeCommand(UnIndentListItemCommand(nodeId: node.id));
      case ListItemNode():
        // Splitting keeps the item's indent.
        InsertNewlineInListItemAtCaretCommand(
          newNodeId,
        ).doInsertNewline(context, executor, caretPosition, caretNodePosition);
      default:
        // An expanded selection's deletion left the caret elsewhere.
        DefaultInsertNewlineAtCaretCommand(
          newNodeId,
        ).doInsertNewline(context, executor, caretPosition, caretNodePosition);
    }
  }
}

class _UnorderedListShortcutKeepingIndent extends UnorderedListItemConversionReaction {
  const _UnorderedListShortcutKeepingIndent();

  @override
  void onPrefixMatched(
    EditContext editContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
    ParagraphNode paragraph,
    String match,
  ) {
    requestDispatcher.execute([
      ReplaceNodeRequest(
        existingNodeId: paragraph.id,
        newNode: ListItemNode.unordered(
          id: paragraph.id,
          text: paragraph.text.copy().removeRegion(startOffset: 0, endOffset: match.length),
          indent: paragraph.indent,
        ),
      ),
      _caretAtStart(paragraph),
    ]);
  }
}

class _OrderedListShortcutKeepingIndent extends OrderedListItemConversionReaction {
  const _OrderedListShortcutKeepingIndent();

  /// [indent] is 0 for a new list, or the level of the list a typed number continues -- an indented line keeps its own.
  @override
  ListItemNode createNextListItemNode(
    ParagraphNode paragraph, {
    required String match,
    required int numberTyped,
    required int indent,
  }) {
    return super.createNextListItemNode(
      paragraph,
      match: match,
      numberTyped: numberTyped,
      indent: paragraph.indent > 0 ? paragraph.indent : indent,
    );
  }
}

class _BlockquoteShortcutKeepingIndent extends BlockquoteConversionReaction {
  const _BlockquoteShortcutKeepingIndent();

  @override
  void onPrefixMatched(
    EditContext editContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
    ParagraphNode paragraph,
    String match,
  ) {
    requestDispatcher.execute([
      ReplaceNodeRequest(
        existingNodeId: paragraph.id,
        newNode: ParagraphNode(
          id: paragraph.id,
          text: AttributedText(),
          indent: paragraph.indent,
          metadata: const {NodeMetadata.blockType: blockquoteAttribution},
        ),
      ),
      _caretAtStart(paragraph),
    ]);
  }
}

ChangeSelectionRequest _caretAtStart(DocumentNode node) {
  return ChangeSelectionRequest(
    DocumentSelection.collapsed(
      position: DocumentPosition(nodeId: node.id, nodePosition: const TextNodePosition(offset: 0)),
    ),
    SelectionChangeType.placeCaret,
    SelectionReason.contentChange,
  );
}
