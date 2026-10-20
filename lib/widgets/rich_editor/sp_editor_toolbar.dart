import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
            _ToolbarStateBuilder(editor: _editor, stateOf: _stateOf, builder: _buildButtons),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  /// Everything the buttons show (keep in step with [_buildButtons] and [_ColorButton]). The buttons rebuild only when
  /// it changes: typing changes none of it, and rebuilding ~30 buttons on every keystroke took a good part of a frame.
  static List<Object?> _stateOf(StoryEditorActions actions) {
    final hasSelection = actions.hasSelection;
    return [
      hasSelection,
      if (hasSelection) ...[
        actions.canMoveSelectedBlocks(up: true),
        actions.canMoveSelectedBlocks(up: false),
      ] else ...[
        actions.canUndo,
        actions.canRedo,
      ],
      actions.headingLevel,
      actions.isBold,
      actions.isItalic,
      actions.isUnderline,
      actions.isStrikethrough,
      actions.textColor,
      actions.backgroundColor,
      actions.alignment,
      actions.isOrderedList,
      actions.isBulletList,
      actions.isTaskList,
      actions.isBlockquote,
      actions.canIndent,
      actions.canOutdent,
      actions.linkUrl,
      actions.canMoveCaret(forward: false),
      actions.canMoveCaret(forward: true),
    ];
  }

  Widget _buildButtons(BuildContext context) {
    final actions = _editor.actions;

    // A lit button is filled (the primary color behind it), as the Quill toolbar's were.
    IconButton toggle(String tooltip, IconData icon, bool selected, VoidCallback? onPressed) {
      return selected
          ? IconButton.filled(tooltip: tooltip, icon: Icon(icon), isSelected: true, onPressed: onPressed)
          : IconButton(tooltip: tooltip, icon: Icon(icon), isSelected: false, onPressed: onPressed);
    }

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      padding: EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        // The view padding: the same at the sides, and the keyboard never changes it (a rebuild per keyboard frame).
        left: MediaQuery.viewPaddingOf(context).left + 8.0,
        right: MediaQuery.viewPaddingOf(context).right + 8.0,
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
          // One button per heading level: tapping the line's own level makes it a paragraph again. A heading on the
          // first line is the page's title; an older story's smaller heading lights none, and any of these replaces it.
          for (final (level, icon) in [(1, SpIcons.heading1), (2, SpIcons.heading2), (3, SpIcons.heading3)])
            toggle(
              tr('button.editor.heading', args: ['$level']),
              icon,
              actions.headingLevel == level,
              () => actions.setHeading(actions.headingLevel == level ? null : level),
            ),
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
          toggle(
            tr('button.editor.link'),
            SpIcons.link,
            actions.linkUrl != null,
            actions.hasSelection || actions.linkUrl != null ? () => _editLink(context) : null,
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

/// Builds [builder] again when the editor's toolbar state ([stateOf]) changes -- not on every editor notification.
class _ToolbarStateBuilder extends StatefulWidget {
  const _ToolbarStateBuilder({required this.editor, required this.stateOf, required this.builder});

  final StoryEditorController editor;
  final List<Object?> Function(StoryEditorActions actions) stateOf;
  final WidgetBuilder builder;

  @override
  State<_ToolbarStateBuilder> createState() => _ToolbarStateBuilderState();
}

class _ToolbarStateBuilderState extends State<_ToolbarStateBuilder> {
  late List<Object?> _state;

  @override
  void initState() {
    super.initState();
    _state = widget.stateOf(widget.editor.actions);
    widget.editor.addListener(_onEditorChanged);
  }

  @override
  void didUpdateWidget(_ToolbarStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editor != widget.editor) {
      oldWidget.editor.removeListener(_onEditorChanged);
      widget.editor.addListener(_onEditorChanged);
      _state = widget.stateOf(widget.editor.actions);
    }
  }

  @override
  void dispose() {
    widget.editor.removeListener(_onEditorChanged);
    super.dispose();
  }

  void _onEditorChanged() {
    final state = widget.stateOf(widget.editor.actions);
    if (listEquals(state, _state)) return;
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Text or highlight color, from the app's color picker. Picking the current color removes it.
class _ColorButton extends StatefulWidget {
  const _ColorButton({required this.editor, required this.background});

  final StoryEditorController editor;
  final bool background;

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton> {
  StoryEditorController get editor => widget.editor;
  bool get background => widget.background;

  // The editor's selection, held while the picker is open (it's in an overlay, outside the editor, and may take
  // focus). Taken on the tap, before the picker opens -- not while it's first built: taking it rebuilds the editor and
  // the toolbar, which mid-way through the picker's first frame spoils its opening animation.
  SelectionHold? _hold;

  Color? get _currentColor => background ? editor.actions.backgroundColor : editor.actions.textColor;

  void _apply(Color? color) {
    background ? editor.actions.setBackgroundColor(color) : editor.actions.setTextColor(color);
  }

  void _release() {
    _hold?.release();
    _hold = null;
  }

  @override
  void dispose() {
    _release();
    super.dispose();
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
        // Released when the picker goes away, picked or dismissed.
        return _OnDispose(
          onDispose: _release,
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
          onPressed: () {
            _hold ??= editor.holdSelection();
            open();
          },
        );
      },
    );
  }
}

/// Calls [onDispose] once unmounted.
class _OnDispose extends StatefulWidget {
  const _OnDispose({required this.onDispose, required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_OnDispose> createState() => _OnDisposeState();
}

class _OnDisposeState extends State<_OnDispose> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
