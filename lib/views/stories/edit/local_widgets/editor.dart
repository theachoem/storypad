part of '../edit_story_view.dart';

class _Editor extends StatelessWidget {
  final QuillController controller;
  final bool showToolbarOnBottom;
  final bool showToolbarOnTop;
  final VoidCallback toggleToolbarPosition;
  final StoryContentDbModel? draftContent;
  final EditStoryViewModel viewModel;
  final EditorKeyboardState keyboardState;

  const _Editor({
    required this.controller,
    required this.showToolbarOnTop,
    required this.showToolbarOnBottom,
    required this.toggleToolbarPosition,
    required this.draftContent,
    required this.viewModel,
    required this.keyboardState,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            buildTopToolbar(context),
            Expanded(child: buildPagesEditor(context)),
            buildBottomToolbar(context),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            height: keyboardState.inAppKeboard ? viewModel.keyboardHeight - MediaQuery.of(context).padding.bottom : 0,
            duration: Durations.medium2,
            curve: Curves.ease,
            child: Wrap(
              children: [
                SizedBox(
                  height: viewModel.keyboardHeight - MediaQuery.of(context).padding.bottom,
                  child: GridView.builder(
                    itemCount: NotoAnimationEmojis.all.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 400 ~/ 80,
                      mainAxisExtent: 150,
                    ),
                    itemBuilder: (context, index) {
                      final emoji = NotoAnimationEmojis.all[index];
                      return Container(
                        color: Colors.red,
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LottieBuilder.network(
                              emoji['src']!,
                              height: 80,
                            ),
                            SizedBox(height: 8.0),
                            Expanded(
                              child: Text(
                                emoji['label']!,
                                textAlign: TextAlign.center,
                                style: TextTheme.of(context).bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget buildTopToolbar(BuildContext context) {
    return Visibility(
      visible: showToolbarOnTop,
      child: SpFadeIn.fromBottom(
        duration: Durations.medium3,
        child: buildToolBar(context),
      ),
    );
  }

  Widget buildBottomToolbar(BuildContext context) {
    print(viewModel.keyboardHeight);
    print(MediaQuery.of(context).padding.bottom);
    return Visibility(
      visible: showToolbarOnBottom,
      child: SpFadeIn.fromTop(
        duration: Durations.medium3,
        child: AnimatedContainer(
          duration: Durations.medium2,
          curve: Curves.ease,
          color: getToolbarBackgroundColor(context),
          padding: EdgeInsets.only(bottom: 0),
          child: buildToolBar(context),
        ),
      ),
    );
  }

  Widget buildPagesEditor(BuildContext context) {
    return QuillEditor.basic(
      controller: controller,
      config: QuillEditorConfig(
        placeholder: "...",
        padding: const EdgeInsets.all(16.0).copyWith(
          bottom: 88 + MediaQuery.of(context).viewPadding.bottom,
        ),
        autoFocus: true,
        enableScribble: true,
        showCursor: true,
        embedBuilders: [
          ImageBlockEmbed(fetchAllImages: () => QuillService.imagesFromContent(draftContent)),
          DateBlockEmbed(),
        ],
        unknownEmbedBuilder: UnknownEmbedBuilder(),
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
        IntrinsicHeight(
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: double.infinity,
                child: buildActualToolbar(context),
              ),
            ),
            const VerticalDivider(width: 1),
            IconButton(
              icon: showToolbarOnTop ? const Icon(Icons.keyboard_arrow_down) : const Icon(Icons.keyboard_arrow_up),
              // onPressed: () => toggleToolbarPosition(),
              onPressed: () => EditorKeyboardManager.of(context)?.toggle(),
            ),
          ]),
        ),
        if (showToolbarOnTop) const Divider(height: 1),
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
              positionedOnUpper: showToolbarOnTop,
            );
          }),
          backgroundColor: QuillToolbarColorButtonOptions(childBuilder: (dynamic options, dynamic extraOptions) {
            extraOptions as QuillToolbarColorButtonExtraOptions;
            return SpQuillToolbarColorButton(
              controller: extraOptions.controller,
              isBackground: true,
              positionedOnUpper: showToolbarOnTop,
            );
          }),
        ),
        multiRowsDisplay: false,
        showDividers: true,
        showFontFamily: false,
        showFontSize: false,
        showBoldButton: true,
        showItalicButton: true,
        showSmallButton: true,
        showUnderLineButton: true,
        showLineHeightButton: false,
        showStrikeThrough: true,
        showInlineCode: true,
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

enum EditorKeyboardState {
  platformBehavior,
  showingInAppKeyboard;

  bool get inAppKeboard {
    return this == showingInAppKeyboard;
  }
}

class EditorKeyboardManager extends StatefulWidget {
  const EditorKeyboardManager({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, EditorKeyboardState keyboardState) builder;

  static EditorKeyboardManagerState? of(BuildContext context) {
    return context.findAncestorStateOfType<EditorKeyboardManagerState>();
  }

  @override
  State<EditorKeyboardManager> createState() => EditorKeyboardManagerState();
}

class EditorKeyboardManagerState extends State<EditorKeyboardManager> {
  EditorKeyboardState state = EditorKeyboardState.platformBehavior;

  void toggle() async {
    state = state.inAppKeboard ? EditorKeyboardState.platformBehavior : EditorKeyboardState.showingInAppKeyboard;

    if (state.inAppKeboard) {
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else {
      await SystemChannels.textInput.invokeMethod('TextInput.show');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, state);
  }
}
