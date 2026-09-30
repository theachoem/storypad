import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_controller.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_scope.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_style.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// A story page: the storypad_editor editor, sized to its content, in the page's scroll view. The page title is the
/// page's leading heading, styled like any other heading.
class StoryPadEditor extends StatefulWidget {
  const StoryPadEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.readOnly,
    required this.storyContent,
    required this.layoutType,
    required this.onChanged,
    required this.onGoToEdit,
  });

  final StoryPadEditorRichTextController controller;

  /// The page's body focus node, which the page and its toolbar listen to.
  final FocusNode focusNode;

  final bool readOnly;
  final StoryContentDbModel storyContent;
  final PageLayoutType? layoutType;

  /// Called after each change to the page's content. `null` for a view whose changes aren't kept, which also turns
  /// checkboxes off.
  final VoidCallback? onChanged;

  /// Opens the story for editing, from a read-only page's context menu.
  final VoidCallback? onGoToEdit;

  @override
  State<StoryPadEditor> createState() => _StoryPadEditorState();
}

class _StoryPadEditorState extends State<StoryPadEditor> {
  StoryEditorController get _editor => widget.controller.editor;

  StoryPadEditorStyle? _style;
  // What the style was built from. Not the ThemeData itself: story themes build a new one on every rebuild, and a new
  // style makes the editor restyle every block.
  (ColorScheme, TextStyle, TargetPlatform)? _styleKey;

  @override
  void initState() {
    super.initState();
    _editor.readOnly = widget.readOnly;
    _attachFocus(widget.focusNode);
    _reportChangesMadeBeforeMount();
  }

  /// Content changed before the editor was built (e.g. a story started from a photo inserts it while the page is
  /// being set up) is reported once mounted: the editor only reports changes made while it's there.
  void _reportChangesMadeBeforeMount() {
    if (!_editor.isDirty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged?.call();
    });
  }

  @override
  void didUpdateWidget(StoryPadEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode || oldWidget.controller != widget.controller) {
      _detachFocus(oldWidget.focusNode, oldWidget.controller.editor);
      _attachFocus(widget.focusNode);
    }
    if (oldWidget.readOnly != widget.readOnly || oldWidget.controller != widget.controller) {
      _editor.readOnly = widget.readOnly;
    }
  }

  @override
  void dispose() {
    _detachFocus(widget.focusNode, _editor);
    super.dispose();
  }

  // The page owns the body focus node (the page and the toolbar listen to it); the editor owns its own. Focus handed
  // to the page's node is passed on to the editor, and the editor's focus is mirrored back to it.
  void _attachFocus(FocusNode pageFocusNode) {
    pageFocusNode.addListener(_onPageFocusChanged);
    _editor.focusNode.addListener(_onEditorFocusChanged);
  }

  void _detachFocus(FocusNode pageFocusNode, StoryEditorController editor) {
    pageFocusNode.removeListener(_onPageFocusChanged);
    editor.focusNode.removeListener(_onEditorFocusChanged);
  }

  void _onPageFocusChanged() {
    if (widget.focusNode.hasFocus && !_editor.focusNode.hasFocus && !widget.readOnly) {
      _editor.focusNode.requestFocus();
    }
  }

  void _onEditorFocusChanged() {
    if (!_editor.focusNode.hasFocus) return;
    // Focused without a caret (e.g. the page was just opened): put it at the end, like the old editor.
    if (_editor.selection.value == null && !widget.readOnly) _editor.actions.placeCaretAtEnd();
  }

  List<StoryContextMenuAction> _buildContextMenuActions() {
    return [
      StoryContextMenuAction(
        label: tr('button.editor.uppercase'),
        onPressed: () => _editor.actions.transformSelectedText((text) => text.toUpperCase()),
      ),
      StoryContextMenuAction(
        label: tr('button.editor.lowercase'),
        onPressed: () => _editor.actions.transformSelectedText((text) => text.toLowerCase()),
      ),
      if (widget.onGoToEdit case final onGoToEdit?)
        StoryContextMenuAction(
          label: tr('button.edit'),
          onPressed: onGoToEdit,
          whenEditing: false,
          whenReadOnly: true,
          needsSelection: false,
        ),
    ];
  }

  StoryPadEditorStyle _styleFor(BuildContext context) {
    final theme = Theme.of(context);
    final key = (theme.colorScheme, DefaultTextStyle.of(context).style, theme.platform);
    if (_style == null || _styleKey != key) {
      _style = StoryPadEditorStyle(context);
      _styleKey = key;
    }
    return _style!;
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context);
    return StoryPadEditorScope(
      layoutType: widget.layoutType,
      fetchAllMedia: () => StoryContentEmbedExtractor.media(widget.storyContent),
      child: Focus(
        focusNode: widget.focusNode,
        skipTraversal: true,
        canRequestFocus: !widget.readOnly,
        child: MarkdownEditor(
          controller: _editor,
          layout: .box,
          // Reported right after each edit (not debounced): the page saves through its own debounce, and a Done tap
          // must never miss the last keystrokes.
          debounce: Duration.zero,
          onChanged: widget.onChanged == null ? null : (_) => widget.onChanged!(),
          padding: const EdgeInsets.only(top: 4, left: 12.0, bottom: 20, right: 12.0),
          baseTextStyle: style.baseTextStyle,
          styleRules: style.styleRules,
          blockStyles: style.blockStyles,
          placeholder: '...',
          placeholderStyle: style.placeholderStyle,
          checkboxesEnabled: widget.onChanged != null,
          onTapLink: (url) => UrlOpenerService.openForRichContent(context: context, url: url),
          contextMenuActions: _buildContextMenuActions(),
        ),
      ),
    );
  }
}
