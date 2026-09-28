import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

import 'held_popup_menu_button.dart';
import 'link_dialog.dart';

const _palette = <(String name, Color color)>[
  ('Red', Color(0xFFE53935)),
  ('Orange', Color(0xFFFB8C00)),
  ('Yellow', Color(0xFFF9A825)),
  ('Green', Color(0xFF43A047)),
  ('Blue', Color(0xFF1E88E5)),
  ('Purple', Color(0xFF8E24AA)),
];

/// Every toolbar button, shared by the desktop and mobile toolbars. Pure presentation over `controller.actions`:
/// each button reads a state getter and calls a command. Build it inside a listener on [controller].
List<Widget> buildToolbarButtons(BuildContext context, StoryEditorController controller) {
  final actions = controller.actions;

  IconButton toggle(String tooltip, IconData icon, bool selected, VoidCallback onPressed) =>
      IconButton(tooltip: tooltip, icon: Icon(icon), isSelected: selected, onPressed: onPressed);

  return [
    IconButton(tooltip: 'Undo', icon: const Icon(Icons.undo), onPressed: actions.canUndo ? actions.undo : null),
    IconButton(tooltip: 'Redo', icon: const Icon(Icons.redo), onPressed: actions.canRedo ? actions.redo : null),
    const _Divider(),
    toggle('Bold', Icons.format_bold, actions.isBold, actions.toggleBold),
    toggle('Italic', Icons.format_italic, actions.isItalic, actions.toggleItalic),
    toggle('Underline', Icons.format_underline, actions.isUnderline, actions.toggleUnderline),
    toggle('Strikethrough', Icons.format_strikethrough, actions.isStrikethrough, actions.toggleStrikethrough),
    toggle('Superscript', Icons.superscript, actions.isSuperscript, actions.toggleSuperscript),
    toggle('Subscript', Icons.subscript, actions.isSubscript, actions.toggleSubscript),
    toggle('Inline code', Icons.code, actions.isInlineCode, actions.toggleInlineCode),
    IconButton(
      tooltip: 'Link',
      icon: const Icon(Icons.link),
      isSelected: actions.linkUrl != null,
      onPressed: actions.hasSelection ? () => showLinkDialog(context, controller) : null,
    ),
    _ColorButton(controller: controller, tooltip: 'Text color', icon: Icons.format_color_text, background: false),
    _ColorButton(controller: controller, tooltip: 'Highlight color', icon: Icons.format_color_fill, background: true),
    IconButton(tooltip: 'Clear formatting', icon: const Icon(Icons.format_clear), onPressed: actions.clearFormatting),
    const _Divider(),
    HeldPopupMenuButton<int>(
      controller: controller,
      tooltip: 'Heading',
      icon: Text(switch (actions.headingLevel) {
        null => 'N',
        final level => 'H$level',
      }),
      onSelected: (level) => actions.setHeading(level == 0 ? null : level),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('Normal')),
        for (var level = 1; level <= 3; level++) PopupMenuItem(value: level, child: Text('Heading $level')),
      ],
    ),
    toggle('Quote', Icons.format_quote, actions.isBlockquote, actions.toggleBlockquote),
    toggle('Code block', Icons.data_object, actions.isCodeBlock, actions.toggleCodeBlock),
    toggle('Checklist', Icons.check_box_outlined, actions.isTaskList, actions.toggleTaskList),
    toggle('Bulleted list', Icons.format_list_bulleted, actions.isBulletList, actions.toggleBulletList),
    toggle('Numbered list', Icons.format_list_numbered, actions.isOrderedList, actions.toggleOrderedList),
    IconButton(
      tooltip: 'Indent',
      icon: const Icon(Icons.format_indent_increase),
      onPressed: actions.canIndent ? actions.indent : null,
    ),
    IconButton(
      tooltip: 'Outdent',
      icon: const Icon(Icons.format_indent_decrease),
      onPressed: actions.canOutdent ? actions.outdent : null,
    ),
    const _Divider(),
    HeldPopupMenuButton<TextAlign>(
      controller: controller,
      tooltip: 'Alignment',
      icon: Icon(_alignIcons[actions.alignment] ?? Icons.format_align_left),
      onSelected: actions.setAlignment,
      itemBuilder: (context) => [
        for (final MapEntry(key: align, value: icon) in _alignIcons.entries)
          PopupMenuItem(
            value: align,
            child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(align.name)]),
          ),
      ],
    ),
    IconButton(
      tooltip: 'Move up',
      icon: const Icon(Icons.arrow_upward),
      onPressed: actions.canMoveSelectedBlocks(up: true) ? () => actions.moveSelectedBlocks(up: true) : null,
    ),
    IconButton(
      tooltip: 'Move down',
      icon: const Icon(Icons.arrow_downward),
      onPressed: actions.canMoveSelectedBlocks(up: false) ? () => actions.moveSelectedBlocks(up: false) : null,
    ),
    IconButton(
      tooltip: 'Horizontal rule',
      icon: const Icon(Icons.horizontal_rule),
      onPressed: actions.insertHorizontalRule,
    ),
  ];
}

const _alignIcons = {
  TextAlign.left: Icons.format_align_left,
  TextAlign.center: Icons.format_align_center,
  TextAlign.right: Icons.format_align_right,
  TextAlign.justify: Icons.format_align_justify,
};

/// A color menu. "None" (a transparent sentinel, since `PopupMenuButton` treats a `null` value as "cancelled")
/// removes the color.
class _ColorButton extends StatelessWidget {
  const _ColorButton({required this.controller, required this.tooltip, required this.icon, required this.background});

  final StoryEditorController controller;
  final String tooltip;
  final IconData icon;
  final bool background;

  static const _none = Color(0x00000000);

  @override
  Widget build(BuildContext context) {
    return HeldPopupMenuButton<Color>(
      controller: controller,
      tooltip: tooltip,
      icon: Icon(icon),
      onSelected: (color) {
        final value = color == _none ? null : color;
        background ? controller.actions.setBackgroundColor(value) : controller.actions.setTextColor(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _none, child: Text('None')),
        for (final (name, color) in _palette)
          PopupMenuItem(
            value: color,
            child: Row(
              children: [
                Container(width: 16, height: 16, color: color),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(height: 24, child: VerticalDivider(width: 1)),
    );
  }
}
