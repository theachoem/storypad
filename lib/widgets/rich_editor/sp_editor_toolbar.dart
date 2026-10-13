import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/rich_editor/sp_editor_controller.dart';
import 'package:storypad/widgets/bottom_sheets/sp_add_media_action_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_recording_sheet.dart';
import 'package:storypad/widgets/sp_color_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// The formatting toolbar for a page body: formatting, headings, lists, alignment, media and block moves, on the
/// editor's actions.
///
/// In the editor's tap region group (so tapping it doesn't count as tapping outside the editor), and holding the
/// editor's selection around every sheet, dialog and picker it opens (they take focus, and a phone's editor drops its
/// selection on losing focus).
class SpEditorToolbar extends StatelessWidget {
  const SpEditorToolbar({super.key, required this.controller});

  final SpEditorController controller;

  StoryEditorController get _editor => controller.editor;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _editor.tapRegionGroupId,
      child: Theme(
        data: Theme.of(context).copyWith(
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            const Divider(height: 1),
            ListenableBuilder(listenable: _editor, builder: (context, _) => _buildButtons(context)),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final actions = _editor.actions;

    IconButton toggle(String tooltip, IconData icon, bool selected, VoidCallback onPressed) {
      return IconButton(tooltip: tooltip, icon: Icon(icon), isSelected: selected, onPressed: onPressed);
    }

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      padding: EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        left: MediaQuery.paddingOf(context).left + 8.0,
        right: MediaQuery.paddingOf(context).right + 8.0,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: tr('button.editor.add_media'),
            icon: const Icon(SpIcons.photo),
            onPressed: () => _editor.keepSelectionWhile(() => _addMedia(context)),
          ),
          _buildDivider(context),
          // With text selected, the undo/redo slots move the selected lines instead (same place, so the toolbar doesn't
          // shift).
          if (actions.hasSelection) ...[
            IconButton(
              tooltip: tr('button.editor.move_up'),
              icon: const Icon(SpIcons.moveUp),
              onPressed: actions.canMoveSelectedBlocks(up: true) ? () => actions.moveSelectedBlocks(up: true) : null,
            ),
            IconButton(
              tooltip: tr('button.editor.move_down'),
              icon: const Icon(SpIcons.moveDown),
              onPressed: actions.canMoveSelectedBlocks(up: false) ? () => actions.moveSelectedBlocks(up: false) : null,
            ),
          ] else ...[
            IconButton(
              tooltip: tr('button.undo'),
              icon: const Icon(SpIcons.undo),
              onPressed: actions.canUndo ? actions.undo : null,
            ),
            IconButton(
              tooltip: tr('button.editor.redo'),
              icon: const Icon(SpIcons.redo),
              onPressed: actions.canRedo ? actions.redo : null,
            ),
          ],
          _buildDivider(context),
          toggle(tr('button.editor.bold'), SpIcons.formatBold, actions.isBold, actions.toggleBold),
          toggle(tr('button.editor.italic'), SpIcons.formatItalic, actions.isItalic, actions.toggleItalic),
          toggle(tr('button.editor.underline'), SpIcons.formatUnderline, actions.isUnderline, actions.toggleUnderline),
          toggle(
            tr('button.editor.strikethrough'),
            SpIcons.formatStrikethrough,
            actions.isStrikethrough,
            actions.toggleStrikethrough,
          ),
          _ColorButton(editor: _editor, background: false),
          _ColorButton(editor: _editor, background: true),
          IconButton(
            tooltip: tr('button.editor.clear_format'),
            icon: const Icon(SpIcons.formatClear),
            onPressed: actions.clearFormatting,
          ),
          _buildDivider(context),
          for (final (align, icon, label) in [
            (TextAlign.left, SpIcons.alignLeft, 'button.editor.align_left'),
            (TextAlign.center, SpIcons.alignCenter, 'button.editor.align_center'),
            (TextAlign.right, SpIcons.alignRight, 'button.editor.align_right'),
            (TextAlign.justify, SpIcons.alignJustify, 'button.editor.align_justify'),
          ])
            toggle(tr(label), icon, actions.alignment == align, () => actions.setAlignment(align)),
          _buildDivider(context),
          // A heading on the first line is the page's title.
          for (final (level, icon) in [(1, SpIcons.heading1), (2, SpIcons.heading2), (3, SpIcons.heading3)])
            toggle(
              tr('button.editor.heading', args: ['$level']),
              icon,
              actions.headingLevel == level,
              () => actions.setHeading(actions.headingLevel == level ? null : level),
            ),
          _buildDivider(context),
          toggle(
            tr('button.editor.numbered_list'),
            SpIcons.listNumbered,
            actions.isOrderedList,
            actions.toggleOrderedList,
          ),
          toggle(
            tr('button.editor.bulleted_list'),
            SpIcons.listBulleted,
            actions.isBulletList,
            actions.toggleBulletList,
          ),
          toggle(tr('button.editor.checklist'), SpIcons.checklist, actions.isTaskList, actions.toggleTaskList),
          toggle(tr('button.editor.quote'), SpIcons.quote, actions.isBlockquote, actions.toggleBlockquote),
          IconButton(
            tooltip: tr('button.editor.indent'),
            icon: const Icon(SpIcons.indentIncrease),
            onPressed: actions.canIndent ? actions.indent : null,
          ),
          IconButton(
            tooltip: tr('button.editor.outdent'),
            icon: const Icon(SpIcons.indentDecrease),
            onPressed: actions.canOutdent ? actions.outdent : null,
          ),
          IconButton(
            tooltip: tr('button.editor.link'),
            icon: const Icon(SpIcons.link),
            isSelected: actions.linkUrl != null,
            onPressed: actions.hasSelection || actions.linkUrl != null ? () => _editLink(context) : null,
          ),
          _buildDivider(context),
          IconButton(
            tooltip: tr('button.cursor_left'),
            icon: const Icon(SpIcons.keyboardLeft),
            onPressed: actions.canMoveCaret(forward: false) ? () => actions.moveCaret(forward: false) : null,
          ),
          IconButton(
            tooltip: tr('button.cursor_right'),
            icon: const Icon(SpIcons.keyboardRight),
            onPressed: actions.canMoveCaret(forward: true) ? () => actions.moveCaret(forward: true) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Theme.of(context).dividerColor,
    );
  }

  Future<void> _editLink(BuildContext context) {
    return _editor.keepSelectionWhile(() async {
      final current = _editor.actions.linkUrl;
      final result = await showTextInputDialog(
        context: context,
        title: current == null ? tr('dialog.editor_link.add_title') : tr('dialog.editor_link.edit_title'),
        okLabel: tr('button.save'),
        textFields: [
          DialogTextField(initialText: current, hintText: 'https://', keyboardType: TextInputType.url),
        ],
      );
      if (result == null) return;

      final url = result.first.trim();
      if (url.isEmpty) {
        _editor.actions.removeLink();
      } else {
        _editor.actions.setLink(url);
      }
    });
  }

  Future<void> _addMedia(BuildContext context) async {
    final action = await SpAddMediaActionSheet.pick(context: context);
    if (!context.mounted || action == null) return;

    switch (action) {
      case .selectFromLibrary:
        await SpImagePickerBottomSheet.showForEditor(context: context, controller: controller);
      case .selectFromPhotos:
        await SpImagePickerBottomSheet.showNativePicker(context: context, controller: controller);
      case .takePhoto:
        await SpImagePickerBottomSheet.showImagePicker(context: context, controller: controller, source: .camera);
      case .recordVideo:
        await SpImagePickerBottomSheet.showVideoPicker(context: context, controller: controller, source: .camera);
      case .recordVoiceNote:
        await SpVoiceRecordingSheet.showForEditor(context: context, controller: controller);
    }
  }
}

/// Text or highlight color, from the app's color picker. Picking the current color removes it.
class _ColorButton extends StatelessWidget {
  const _ColorButton({required this.editor, required this.background});

  final StoryEditorController editor;
  final bool background;

  Color? get _currentColor => background ? editor.actions.backgroundColor : editor.actions.textColor;

  void _apply(Color? color) {
    background ? editor.actions.setBackgroundColor(color) : editor.actions.setTextColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == .dark;
    final current = _currentColor;
    final iconColor = Theme.of(context).iconTheme.color;

    // A picked color tints the icon; on a background too close to the color, it fills the button instead.
    Color? fillColor;
    Color? displayIconColor = iconColor;
    if (current != null) {
      final lightColor = ThemeData.estimateBrightnessForColor(current) == .light;
      if (lightColor == isDarkMode) {
        displayIconColor = current;
      } else {
        fillColor = current;
      }
    }

    return SpFloatingPopUpButton(
      estimatedFloatingWidth: spColorPickerMinWidth,
      bottomToTop: true,
      dyGetter: (dy) => dy - (spOnPickingColorHeight * 2 - 8),
      floatingBuilder: (close) {
        // Held while the picker is open (it's in an overlay, outside the editor, and may take focus); released when
        // the picker goes away, picked or dismissed.
        return _SelectionHolder(
          editor: editor,
          child: TapRegion(
            groupId: editor.tapRegionGroupId,
            child: SpColorPicker(
              isDarkMode: isDarkMode,
              position: SpColorPickerPosition.bottom,
              currentColor: current,
              level: SpColorPickerLevel.two,
              onPickedColor: (color) {
                _apply(color == current ? null : color);
                close();
              },
            ),
          ),
        );
      },
      builder: (open) {
        return IconButton(
          tooltip: background ? tr('button.editor.highlight_color') : tr('button.editor.text_color'),
          icon: Icon(background ? SpIcons.formatHighlight : SpIcons.formatColor, color: displayIconColor),
          style: ButtonStyle(backgroundColor: fillColor != null ? WidgetStatePropertyAll(fillColor) : null),
          onPressed: open,
        );
      },
    );
  }
}

/// Holds [editor]'s selection for as long as it's mounted.
class _SelectionHolder extends StatefulWidget {
  const _SelectionHolder({required this.editor, required this.child});

  final StoryEditorController editor;
  final Widget child;

  @override
  State<_SelectionHolder> createState() => _SelectionHolderState();
}

class _SelectionHolderState extends State<_SelectionHolder> {
  late final SelectionHold _hold = widget.editor.holdSelection();

  @override
  void initState() {
    super.initState();
    _hold;
  }

  @override
  void dispose() {
    _hold.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
