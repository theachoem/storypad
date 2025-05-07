part of '../edit_story_view.dart';

class _Editor extends StatelessWidget {
  final QuillController controller;
  final FocusNode titleFocusNode;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final StoryContentDbModel? draftContent;
  final StoryDbModel? story;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  const _Editor({
    required this.controller,
    required this.titleFocusNode,
    required this.focusNode,
    required this.scrollController,
    required this.draftContent,
    required this.story,
    required this.onThemeChanged,
  });

  Color? getToolbarBackgroundColor(BuildContext context) => ColorScheme.of(context).readOnly.surface1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: buildPagesEditor(context)),
        buildBodyToolbar(context),
        if (story != null) buildTitleToolbar(context, story!.preferences),
      ],
    );
  }

  Widget buildBodyToolbar(BuildContext context) {
    return SpFocusNodeBuilder(
      focusNode: titleFocusNode,
      child: AnimatedContainer(
        duration: Durations.medium1,
        curve: Curves.ease,
        color: getToolbarBackgroundColor(context),
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
          bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _QuillToolbar(
            controller: controller, context: context, backgroundColor: getToolbarBackgroundColor(context)),
      ),
      builder: (context, titleFocused, child) {
        return Visibility(
          visible: !titleFocused,
          child: SpFadeIn.fromBottom(
            child: child!,
          ),
        );
      },
    );
  }

  Widget buildTitleToolbar(BuildContext context, StoryPreferencesDbModel preferences) {
    return SpFocusNodeBuilder(
      focusNode: titleFocusNode,
      builder: (context, titleFocused, _) {
        return Visibility(
          visible: titleFocused,
          child: SpFadeIn.fromBottom(
            child: AnimatedContainer(
              duration: Durations.medium1,
              curve: Curves.ease,
              color: getToolbarBackgroundColor(context),
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).padding.left,
                right: MediaQuery.of(context).padding.right,
                bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              ),
              width: double.infinity,
              child: _TitleToolbar(
                preferences: preferences,
                onThemeChanged: onThemeChanged,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPagesEditor(BuildContext context) {
    return QuillEditor.basic(
      focusNode: focusNode,
      controller: controller,
      scrollController: scrollController,
      config: QuillEditorConfig(
        keyboardAppearance: Theme.of(context).brightness,
        contextMenuBuilder: (context, rawEditorState) => QuillContextMenuHelper.get(rawEditorState, editable: true),
        scrollBottomInset: MediaQuery.of(context).viewPadding.bottom,
        scrollable: true,
        expands: true,
        placeholder: "...",
        quillMagnifierBuilder: defaultQuillMagnifierBuilder,
        padding: EdgeInsets.only(
          top: 16.0,
          bottom: 88 + MediaQuery.of(context).viewPadding.bottom,
          left: MediaQuery.of(context).padding.left + 16,
          right: MediaQuery.of(context).padding.right + 16,
        ),
        autoFocus: true,
        enableScribble: true,
        showCursor: true,
        paintCursorAboveText: true,
        embedBuilders: [
          SpImageBlockEmbed(fetchAllImages: () => StoryExtractImageFromContentService.call(draftContent)),
          SpDateBlockEmbed(),
        ],
        unknownEmbedBuilder: SpQuillUnknownEmbedBuilder(),
      ),
    );
  }
}
