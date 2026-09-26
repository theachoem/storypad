import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../markdown/markdown_format.dart' show maxIndent;

/// Tab-to-indent for tasks, without SuperEditor's stock `tabToIndentTask`'s
/// restriction that a task can only indent one level deeper than whatever
/// task sits directly above it.
///
/// List items' own stock `tabToIndentListItem` has no such restriction —
/// they indent freely up to a fixed max level regardless of what precedes
/// them — so pressing Tab on a list item always works, while the stock task
/// handler silently does nothing for the common case of a standalone
/// checkbox, or one preceded by a paragraph. This gives tasks that same
/// freedom, matching `StoryEditorActions.indent`. `SetTaskIndentRequest`
/// specifically (not `ReplaceNodeRequest`) reports a plain node change, so no
/// deletion-triggered reaction can undo it.
///
/// Swap this in for `tabToIndentTask` in `SuperEditor.keyboardActions` (see
/// `RawEditor`) — don't add it alongside; only one of the two should run per
/// keypress.
ExecutionInstruction tabToIndentTaskFreely({required SuperEditorContext editContext, required KeyEvent keyEvent}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    // Don't indent if Shift is pressed - that's for un-indenting.
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || selection.base.nodeId != selection.extent.nodeId) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! TaskNode || node.indent >= maxIndent) {
    return ExecutionInstruction.continueExecution;
  }

  editContext.editor.execute([SetTaskIndentRequest(node.id, node.indent + 1)]);

  return ExecutionInstruction.haltExecution;
}

/// The outdenting counterpart to [tabToIndentTaskFreely] — swap in for
/// `shiftTabToUnIndentTask`. See that function's doc comment.
ExecutionInstruction shiftTabToUnIndentTaskFreely({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }
  if (!HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null || selection.base.nodeId != selection.extent.nodeId) {
    return ExecutionInstruction.continueExecution;
  }

  final node = editContext.document.getNodeById(selection.extent.nodeId);
  if (node is! TaskNode || node.indent <= 0) {
    return ExecutionInstruction.continueExecution;
  }

  editContext.editor.execute([SetTaskIndentRequest(node.id, node.indent - 1)]);

  return ExecutionInstruction.haltExecution;
}
