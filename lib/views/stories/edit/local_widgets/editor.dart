part of '../edit_story_view.dart';

class _Editor extends StatelessWidget {
  final QuillController controller;
  final FocusNode titleFocusNode;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final StoryContentDbModel? draftContent;

  const _Editor({
    required this.controller,
    required this.titleFocusNode,
    required this.focusNode,
    required this.scrollController,
    required this.draftContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: buildPagesEditor(context)),
        SpFocusNodeBuilder(
          focusNode: titleFocusNode,
          child: buildBottomToolbar(context),
          builder: (context, titleFocused, child) {
            return Visibility(
              maintainState: true,
              visible: !titleFocused,
              child: SpFadeIn.fromBottom(
                child: child!,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildBottomToolbar(BuildContext context) {
    return AnimatedContainer(
      duration: Durations.medium1,
      curve: Curves.ease,
      color: getToolbarBackgroundColor(context),
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: buildToolBar(context),
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

  Widget buildToolBar(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
          ),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: buildActualToolbar(context)),
        const Divider(height: 1),
      ]),
    );
  }

  Color? getToolbarBackgroundColor(BuildContext context) => ColorScheme.of(context).readOnly.surface1;

  Widget buildActualToolbar(BuildContext context) {
    return QuillSimpleToolbar(
      controller: controller,
      config: QuillSimpleToolbarConfig(
        color: getToolbarBackgroundColor(context),
        buttonOptions: QuillSimpleToolbarButtonOptions(
          color: QuillToolbarColorButtonOptions(childBuilder: (dynamic options, dynamic extraOptions) {
            extraOptions as QuillToolbarColorButtonExtraOptions;
            return SpQuillToolbarColorButton(
              controller: extraOptions.controller,
              isBackground: false,
              positionedOnUpper: false,
            );
          }),
          backgroundColor: QuillToolbarColorButtonOptions(childBuilder: (dynamic options, dynamic extraOptions) {
            extraOptions as QuillToolbarColorButtonExtraOptions;
            return SpQuillToolbarColorButton(
              controller: extraOptions.controller,
              isBackground: true,
              positionedOnUpper: false,
            );
          }),
        ),
        embedButtons: [
          (context, embedContext) {
            return const VerticalDivider(
              indent: 12,
              endIndent: 12,
            );
          },
          (context, embedContext) {
            return IconButton(
              tooltip: FlutterQuillLocalizations.of(context)?.image,
              icon: const Icon(SpIcons.photo),
              onPressed: () => SpImagePickerBottomSheet.showQuillPicker(context: context, controller: controller),
            );
          },
        ],
        multiRowsDisplay: false,
        showDividers: true,
        showFontFamily: false,
        showFontSize: false,
        showBoldButton: true,
        showItalicButton: true,
        showSmallButton: false,
        showUnderLineButton: true,
        showLineHeightButton: false,
        showStrikeThrough: true,
        showInlineCode: false,
        showColorButton: true,
        showBackgroundColorButton: true,
        showClearFormat: true,
        showAlignmentButtons: true,
        showLeftAlignment: true,
        showCenterAlignment: true,
        showRightAlignment: true,
        showJustifyAlignment: true,
        showHeaderStyle: false,
        showListNumbers: true,
        showListBullets: true,
        showListCheck: true,
        showCodeBlock: false,
        showQuote: true,
        showIndent: true,
        showLink: true,
        showUndo: true,
        showRedo: true,
        showDirection: false,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        showClipboardCut: false,
        showClipboardCopy: false,
        showClipboardPaste: false,
      ),
    );
  }
}
