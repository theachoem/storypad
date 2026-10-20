import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../../markdown/markdown_format.dart' show MarkdownFormat;

/// Tab and Shift+Tab for tasks, without SuperEditor's stock `tabToIndentTask`'s restriction that a task can only
/// indent one level deeper than whatever task sits directly above it.
///
/// List items' own stock `tabToIndentListItem` has no such restriction -- they indent freely up to a fixed max level
/// regardless of what precedes them -- so pressing Tab on a list item always works, while the stock task handler
/// silently does nothing for the common case of a standalone checkbox, or one preceded by a paragraph. This gives tasks
/// that same freedom, matching `StoryEditorActions.indent`. `SetTaskIndentRequest` specifically (not
/// `ReplaceNodeRequest`) reports a plain node change, so no deletion-triggered reaction can undo it.
///
/// Swap [tab] in for `tabToIndentTask`, and [shiftTab] for `shiftTabToUnIndentTask`, in `SuperEditor.keyboardActions`
/// (see `RawEditor`) -- don't add them alongside; only one of each pair should run per keypress.
class FreeTaskIndent {
  const FreeTaskIndent._();

  /// Tab: indents the task holding the caret one level, up to [MarkdownFormat.maxIndent].
  static ExecutionInstruction tab({required SuperEditorContext editContext, required KeyEvent keyEvent}) {
    // Shift+Tab is for outdenting.
    if (HardwareKeyboard.instance.isShiftPressed) return ExecutionInstruction.continueExecution;
    return _indent(editContext, keyEvent, by: 1);
  }

  /// Shift+Tab: outdents the task holding the caret one level.
  static ExecutionInstruction shiftTab({required SuperEditorContext editContext, required KeyEvent keyEvent}) {
    if (!HardwareKeyboard.instance.isShiftPressed) return ExecutionInstruction.continueExecution;
    return _indent(editContext, keyEvent, by: -1);
  }

  /// Moves the task holding the caret [by] levels, when [keyEvent] is a Tab press and the result stays in range.
  static ExecutionInstruction _indent(SuperEditorContext editContext, KeyEvent keyEvent, {required int by}) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) return ExecutionInstruction.continueExecution;
    if (keyEvent.logicalKey != LogicalKeyboardKey.tab) return ExecutionInstruction.continueExecution;

    final selection = editContext.composer.selection;
    if (selection == null || selection.base.nodeId != selection.extent.nodeId) {
      return ExecutionInstruction.continueExecution;
    }

    final node = editContext.document.getNodeById(selection.extent.nodeId);
    if (node is! TaskNode) return ExecutionInstruction.continueExecution;

    final indent = node.indent + by;
    if (indent < 0 || indent > MarkdownFormat.maxIndent) return ExecutionInstruction.continueExecution;

    editContext.editor.execute([SetTaskIndentRequest(node.id, indent)]);
    return ExecutionInstruction.haltExecution;
  }
}
