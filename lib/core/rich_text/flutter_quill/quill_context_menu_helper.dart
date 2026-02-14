part of 'quill_adapter.dart';

/// Context menu helper for QuillEditor.
///
/// Uses flutter_quill's internal QuillRawEditorState passed by the
/// contextMenuBuilder callback to access selection actions.
class _QuillContextMenuHelper {
  static AdaptiveTextSelectionToolbar get(
    quill.QuillRawEditorState rawEditorState, {
    required bool editable,
    void Function()? onEdit,
  }) {
    final text = rawEditorState.textEditingValue.selection.textInside(rawEditorState.textEditingValue.text);

    List<ContextMenuButtonItem> buttonItems = EditableText.getEditableButtonItems(
      clipboardStatus: ClipboardStatus.pasteable,
      onCopy: () => rawEditorState.copySelection(SelectionChangedCause.toolbar),
      onCut: editable ? () => rawEditorState.cutSelection(SelectionChangedCause.toolbar) : null,
      onPaste: editable ? () => rawEditorState.pasteText(SelectionChangedCause.toolbar) : null,
      onSelectAll: () => rawEditorState.selectAll(SelectionChangedCause.toolbar),
      onSearchWeb: Platform.isIOS ? () => rawEditorState.searchWebForSelection(SelectionChangedCause.toolbar) : null,
      onShare: () => rawEditorState.shareSelection(SelectionChangedCause.toolbar),
      onLiveTextInput: null,
      onLookUp: defaultTargetPlatform == TargetPlatform.iOS
          ? () => rawEditorState.lookUpSelection(SelectionChangedCause.toolbar)
          : null,
    );

    for (final ProcessTextAction action in kProcessTextActions) {
      buttonItems.add(
        ContextMenuButtonItem(
          label: action.label,
          onPressed: () async {
            if (text.isNotEmpty) {
              final String? processedText = await DefaultProcessTextService().processTextAction(
                action.id,
                text,
                rawEditorState.controller.readOnly,
              );

              // If an activity does not return a modified version, just hide the toolbar.
              // Otherwise use the result to replace the selected text.
              if (processedText != null && rawEditorState.controller.readOnly) {
                int index = rawEditorState.controller.selection.start;
                int length = rawEditorState.controller.selection.end - index;

                rawEditorState.controller.replaceText(
                  index,
                  length,
                  processedText,
                  rawEditorState.controller.selection,
                );

                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (rawEditorState.mounted) {
                    rawEditorState.bringIntoView(rawEditorState.textEditingValue.selection.extent);
                  }
                }, debugLabel: 'EditableText.bringSelectionIntoView');
              }

              rawEditorState.hideToolbar();
            }
          },
        ),
      );
    }

    if (!editable) {
      buttonItems.insert(
        0,
        ContextMenuButtonItem(
          label: rawEditorState.context.loc.edit,
          onPressed: onEdit,
        ),
      );
    }

    if (editable) {
      int index = rawEditorState.controller.selection.start;
      int length = rawEditorState.controller.selection.end - index;

      buttonItems.addAll([
        ContextMenuButtonItem(
          label: "Uppercase",
          onPressed: () => rawEditorState.controller.replaceText(
            index,
            length,
            text.toUpperCase(),
            rawEditorState.controller.selection,
          ),
        ),
        ContextMenuButtonItem(
          label: "Lowercase",
          onPressed: () => rawEditorState.controller.replaceText(
            index,
            length,
            text.toLowerCase(),
            rawEditorState.controller.selection,
          ),
        ),
      ]);
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: buttonItems,
      anchors: rawEditorState.contextMenuAnchors,
    );
  }
}
