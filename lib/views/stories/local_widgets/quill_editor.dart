part of 'story_pages_builder.dart';

class _QuillEditor extends StatefulWidget {
  const _QuillEditor({
    required this.bodyFocusNode,
    required this.bodyController,
    required this.scrollController,
    required this.readOnly,
    required this.storyContent,
    required this.onChanged,
    required this.onGoToEdit,
  });

  final FocusNode bodyFocusNode;
  final QuillController bodyController;
  final ScrollController scrollController;
  final bool readOnly;
  final StoryContentDbModel storyContent;
  final void Function()? onChanged;
  final void Function()? onGoToEdit;

  @override
  State<_QuillEditor> createState() => _QuillEditorState();
}

class _QuillEditorState extends State<_QuillEditor> {
  @override
  void initState() {
    super.initState();
    widget.bodyController.addListener(_listener);
    widget.bodyFocusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    widget.bodyController.removeListener(_listener);
    widget.bodyFocusNode.removeListener(_focusListener);
    super.dispose();
  }

  void _listener() {
    widget.onChanged?.call();
  }

  void _focusListener() {
    // TODO: temporary fix stuck not seeing cursor
    if (widget.bodyFocusNode.hasFocus) {
      if (widget.bodyController.selection.isCollapsed &&
          widget.bodyController.selection.baseOffset == 0 &&
          widget.bodyController.selection.extentOffset == 0 &&
          widget.bodyController.selection.affinity == TextAffinity.downstream) {
        widget.bodyController.moveCursorToEnd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      focusNode: widget.bodyFocusNode,
      controller: widget.bodyController,
      scrollController: widget.scrollController,
      config: QuillEditorConfig(
        keyboardAppearance: Theme.of(context).brightness,
        contextMenuBuilder: (context, rawEditorState) => QuillContextMenuHelper.get(
          rawEditorState,
          editable: !widget.readOnly,
          onEdit: widget.onGoToEdit,
        ),
        scrollBottomInset: MediaQuery.of(context).viewPadding.bottom,
        scrollable: true,
        expands: false,
        quillMagnifierBuilder: null,
        padding: const EdgeInsets.only(top: 4, left: 12.0, bottom: 20, right: 12.0),
        autoFocus: false,
        checkBoxReadOnly: widget.onChanged == null ? true : (widget.readOnly ? false : null),
        enableScribble: !widget.readOnly,
        showCursor: !widget.readOnly,
        paintCursorAboveText: !widget.readOnly,
        placeholder: "...",
        embedBuilders: [
          SpImageBlockEmbed(
            fetchAllImages: () => StoryExtractImageFromContentService.call(widget.storyContent),
          ),
          SpDateBlockEmbed(),
        ],
        unknownEmbedBuilder: SpQuillUnknownEmbedBuilder(),
      ),
    );
  }
}
