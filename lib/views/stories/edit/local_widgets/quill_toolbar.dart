part of '../edit_story_view.dart';

class _QuillToolbar extends StatelessWidget {
  const _QuillToolbar({
    required this.controller,
    required this.context,
    required this.backgroundColor,
  });

  final QuillController controller;
  final BuildContext context;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
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
        Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: buidlToolbar(context)),
        const Divider(height: 1),
      ]),
    );
  }

  Widget buidlToolbar(BuildContext context) {
    return QuillSimpleToolbar(
      controller: controller,
      config: QuillSimpleToolbarConfig(
        color: backgroundColor,
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
