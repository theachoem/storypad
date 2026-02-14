part of 'quill_adapter.dart';

/// Builds a QuillToolbar widget from a RichTextController.
///
/// This is an adapter function that bridges the abstraction layer
/// (RichTextController) to the flutter_quill implementation (QuillSimpleToolbar).
Widget buildQuillToolbar({
  required BuildContext context,
  required RichTextController controller,
  Color? backgroundColor,
}) {
  return _QuillToolbarWidget(
    controller: controller,
    context: context,
    backgroundColor: backgroundColor,
  );
}

/// Internal QuillToolbar widget implementation.
class _QuillToolbarWidget extends StatelessWidget {
  const _QuillToolbarWidget({
    required this.controller,
    required this.context,
    required this.backgroundColor,
  });

  final RichTextController controller;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          _buildToolbar(context),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    // Access underlying QuillController for flutter_quill widgets that require it
    final quillController = (controller as QuillRichTextController).quillController;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        left: MediaQuery.of(context).padding.left + 6.0,
        right: MediaQuery.of(context).padding.right + 6.0,
      ),
      child: Row(
        children: [
          if (kSupportCamera)
            IconButton(
              tooltip: tr('button.take_photo'),
              icon: const Icon(SpIcons.camera),
              onPressed: () => SpImagePickerBottomSheet.showImagePicker(
                context: context,
                controller: controller,
                source: ImageSource.camera,
              ),
            ),
          IconButton(
            tooltip: quill.FlutterQuillLocalizations.of(context)?.image,
            icon: const Icon(SpIcons.photo),
            onPressed: () => SpImagePickerBottomSheet.showQuillPicker(context: context, controller: controller),
          ),
          Consumer<InAppPurchaseProvider>(
            builder: (context, provider, child) {
              return IconButton(
                tooltip: tr('button.record_voice'),
                icon: provider.voiceJournal
                    ? const Icon(SpIcons.voice)
                    : const Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(SpIcons.voice),
                          Positioned(
                            top: 0,
                            right: -8,
                            child: Icon(SpIcons.lock, size: 12.0),
                          ),
                        ],
                      ),
                onPressed: () {
                  if (provider.voiceJournal) {
                    SpVoiceRecordingSheet.showQuillRecorder(context: context, controller: controller);
                  } else {
                    AddOnsRoute.pushAndNavigateTo(
                      product: AppProduct.voice_journal,
                      context: context,
                    );
                  }
                },
              );
            },
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
            ),
          ),
          quill.QuillSimpleToolbar(
            controller: quillController,
            config: quill.QuillSimpleToolbarConfig(
              color: backgroundColor,
              buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                color: quill.QuillToolbarColorButtonOptions(
                  childBuilder: (dynamic options, dynamic extraOptions) {
                    return _QuillRichTextColorButton(
                      controller: controller,
                      isBackground: false,
                      positionedOnUpper: false,
                    );
                  },
                ),
                backgroundColor: quill.QuillToolbarColorButtonOptions(
                  childBuilder: (dynamic options, dynamic extraOptions) {
                    return _QuillRichTextColorButton(
                      controller: controller,
                      isBackground: true,
                      positionedOnUpper: false,
                    );
                  },
                ),
              ),
              multiRowsDisplay: true,
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
            ),
          ),
        ],
      ),
    );
  }
}
