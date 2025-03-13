// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/internal.dart';
import 'package:storypad/core/services/native_look_up_text_service.dart';
import 'package:storypad/core/services/validator/validator.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class QuillContextMenuHelper {
  static AdaptiveTextSelectionToolbar get(
    QuillRawEditorState rawEditorState, {
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
      onLookUp: NativeLookUpTextService.call(text),
    );

    if (!editable) {
      buttonItems.insert(
        0,
        ContextMenuButtonItem(
          label: rawEditorState.context.loc.edit,
          onPressed: onEdit,
        ),
      );
    }

    if (isEmail(text.trim())) {
      buttonItems.add(
        ContextMenuButtonItem(
          label: tr("button.open"),
          onPressed: () {
            final Uri uri = Uri.parse("mailto:${text.trim()}");
            launcher.launchUrl(uri);
          },
        ),
      );
    }

    if (editable) {
      int index = rawEditorState.controller.selection.start;
      int length = rawEditorState.controller.selection.end - index;

      buttonItems.addAll([
        ContextMenuButtonItem(
          label: "Uppercase",
          onPressed: () => rawEditorState.controller
              .replaceText(index, length, text.toUpperCase(), rawEditorState.controller.selection),
        ),
        ContextMenuButtonItem(
          label: "Lowercase",
          onPressed: () => rawEditorState.controller
              .replaceText(index, length, text.toLowerCase(), rawEditorState.controller.selection),
        ),
      ]);
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: buttonItems,
      anchors: rawEditorState.contextMenuAnchors,
    );
  }

  static AdaptiveTextSelectionToolbar toolbar(QuillRawEditorState rawEditorState) {
    final List<ContextMenuButtonItem> items = [
      ContextMenuButtonItem(
        onPressed: () => rawEditorState.controller.formatSelection(Attribute.bold),
        type: ContextMenuButtonType.custom,
        label: rawEditorState.context.loc.bold,
      ),
      ContextMenuButtonItem(
        onPressed: () => rawEditorState.controller.formatSelection(Attribute.italic),
        type: ContextMenuButtonType.custom,
        label: rawEditorState.context.loc.italic,
      ),
      ContextMenuButtonItem(
        onPressed: () => rawEditorState.controller.formatSelection(Attribute.underline),
        type: ContextMenuButtonType.custom,
        label: rawEditorState.context.loc.underline,
      ),
      ContextMenuButtonItem(
        onPressed: () => rawEditorState.controller.formatSelection(Attribute.strikeThrough),
        type: ContextMenuButtonType.custom,
        label: rawEditorState.context.loc.strikeThrough,
      ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.custom,
        label: rawEditorState.context.loc.clearFormat,
        onPressed: () {
          for (final style in rawEditorState.controller.getAllSelectionStyles()) {
            for (final attr in style.attributes.values) {
              rawEditorState.controller.formatSelection(Attribute.clone(attr, null));
            }
          }
        },
      ),
    ];

    return AdaptiveTextSelectionToolbar.buttonItems(
      buttonItems: items,
      anchors: rawEditorState.contextMenuAnchors,
    );
  }
}
