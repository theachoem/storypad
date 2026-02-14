import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/rich_text/adapters/quill_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_recording_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_rich_text_color_button.dart';

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
                controller: quillController,
                source: ImageSource.camera,
              ),
            ),
          IconButton(
            tooltip: FlutterQuillLocalizations.of(context)?.image,
            icon: const Icon(SpIcons.photo),
            onPressed: () => SpImagePickerBottomSheet.showQuillPicker(context: context, controller: quillController),
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
                    SpVoiceRecordingSheet.showQuillRecorder(context: context, controller: quillController);
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
          QuillSimpleToolbar(
            controller: quillController,
            config: QuillSimpleToolbarConfig(
              color: backgroundColor,
              buttonOptions: QuillSimpleToolbarButtonOptions(
                color: QuillToolbarColorButtonOptions(
                  childBuilder: (dynamic options, dynamic extraOptions) {
                    return SpRichTextColorButton(
                      controller: controller,
                      isBackground: false,
                      positionedOnUpper: false,
                    );
                  },
                ),
                backgroundColor: QuillToolbarColorButtonOptions(
                  childBuilder: (dynamic options, dynamic extraOptions) {
                    return SpRichTextColorButton(
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
