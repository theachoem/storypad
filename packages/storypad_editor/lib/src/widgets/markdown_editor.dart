import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

import '../controller/story_editor_controller.dart';
import 'desktop_context_menu.dart';
import 'link_tap_handler.dart';
import 'raw_editor.dart';

/// A [RawEditor] that reports the document as Markdown whenever it changes -- the format StoryPad stores.
///
/// ```dart
/// MarkdownEditor(
///   controller: controller,
///   onChanged: (markdown) => story.save(body: markdown),
/// );
/// ```
///
/// [onChanged] is debounced by [debounce] (a burst of keystrokes is one call), and only fires when the Markdown
/// actually differs from the last reported value (a selection change isn't a change). A change still pending when the
/// editor is disposed (or given another controller) is flushed, so the last edit is never lost -- in a microtask right
/// after, since the widget tree is locked at that moment; check `mounted` before calling `setState` from it.
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    required this.controller,
    this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
    this.baseTextStyle,
    this.padding,
    this.styleRules = const [],
    this.scrollController,
    this.autofocus = false,
    this.inputRole,
    this.shrinkWrap = false,
    this.desktopContextMenu = showDefaultDesktopContextMenu,
    this.onTapLink,
  });

  final StoryEditorController controller;

  /// Called with the document's canonical Markdown after it changes. See the class doc for when.
  final ValueChanged<String>? onChanged;

  /// How long edits must pause before [onChanged] fires. [Duration.zero] reports every change right after it's made.
  final Duration debounce;

  /// See [RawEditor.baseTextStyle].
  final TextStyle? baseTextStyle;

  /// See [RawEditor.padding].
  final EdgeInsets? padding;

  /// See [RawEditor.styleRules].
  final List<StyleRule> styleRules;

  /// See [RawEditor.scrollController].
  final ScrollController? scrollController;

  /// See [RawEditor.autofocus].
  final bool autofocus;

  /// See [RawEditor.inputRole].
  final String? inputRole;

  /// See [RawEditor.shrinkWrap].
  final bool shrinkWrap;

  /// See [RawEditor.desktopContextMenu].
  final DesktopContextMenuHandler? desktopContextMenu;

  /// See [RawEditor.onTapLink].
  final LinkTapCallback? onTapLink;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  Timer? _debounce;
  bool _reportScheduled = false;
  late String _reported;

  @override
  void initState() {
    super.initState();
    _listen(widget.controller);
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _flush(oldWidget);
      oldWidget.controller.documentRevision.removeListener(_onDocumentChanged);
      _listen(widget.controller);
    }
  }

  @override
  void dispose() {
    _flush(widget);
    widget.controller.documentRevision.removeListener(_onDocumentChanged);
    super.dispose();
  }

  void _listen(StoryEditorController controller) {
    _reported = controller.toMarkdown();
    controller.documentRevision.addListener(_onDocumentChanged);
  }

  void _onDocumentChanged() {
    if (widget.debounce == Duration.zero) {
      // Right after the current edit completes (a change reported mid-edit could re-enter the editor); edits made in
      // one synchronous block are reported once.
      if (_reportScheduled) return;
      _reportScheduled = true;
      scheduleMicrotask(() {
        if (!_reportScheduled || !mounted) return; // Already flushed.
        _reportScheduled = false;
        _report();
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, _report);
  }

  /// Reports [editor]'s pending change, if there is one, in a microtask (the tree is locked during dispose/update).
  void _flush(MarkdownEditor editor) {
    if (!(_debounce?.isActive ?? false) && !_reportScheduled) return;
    _debounce?.cancel();
    _debounce = null;
    _reportScheduled = false;

    final markdown = editor.controller.toMarkdown();
    if (markdown == _reported) return;
    _reported = markdown;
    final onChanged = editor.onChanged;
    if (onChanged != null) scheduleMicrotask(() => onChanged(markdown));
  }

  void _report() {
    _debounce = null;
    final markdown = widget.controller.toMarkdown();
    if (markdown == _reported) return;
    _reported = markdown;
    widget.onChanged?.call(markdown);
  }

  @override
  Widget build(BuildContext context) {
    return RawEditor(
      controller: widget.controller,
      baseTextStyle: widget.baseTextStyle,
      padding: widget.padding,
      styleRules: widget.styleRules,
      scrollController: widget.scrollController,
      autofocus: widget.autofocus,
      inputRole: widget.inputRole,
      shrinkWrap: widget.shrinkWrap,
      desktopContextMenu: widget.desktopContextMenu,
      onTapLink: widget.onTapLink,
    );
  }
}
