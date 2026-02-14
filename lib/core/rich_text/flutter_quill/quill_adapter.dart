import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:animated_clipper/animated_clipper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_info_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_recording_sheet.dart';
import 'package:storypad/widgets/sp_color_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_image.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_voice_player.dart';

// ignore: experimental_member_use
import 'package:flutter_quill/internal.dart';

part 'quill_rich_text_adapter.dart';
part 'quill_editor_builder.dart';
part 'quill_toolbar_builder.dart';
part 'quill_rich_text_color_button.dart';
part 'quill_context_menu_helper.dart';
part 'custom_attributes/quill_embed_alignment_attribute.dart';
part 'custom_attributes/quill_embed_size_attribute.dart';
part 'custom_embeds/quill_audio_block_embed.dart';
part 'custom_embeds/quill_image_block_embed.dart';
part 'custom_embeds/quill_date_block_embed.dart';
part 'custom_embeds/quill_unknown_embed_builder.dart';

/// Adapter implementation of [RichTextController] using flutter_quill.
///
/// This adapter wraps [quill.QuillController] and implements the abstract
/// RichTextController interface, isolating flutter_quill dependencies.
class QuillRichTextController extends RichTextController {
  /// The underlying QuillController instance
  final quill.QuillController _quillController;

  QuillRichTextController({
    required quill.Document document,
    required TextSelection selection,
    bool readOnly = false,
  }) : _quillController = quill.QuillController(
         document: document,
         selection: selection,
         readOnly: readOnly,
       ) {
    // Forward notifications from QuillController
    _quillController.addListener(_onQuillControllerChanged);
  }

  /// Factory constructor from JSON (for loading from database)
  factory QuillRichTextController.fromJson({
    required List<dynamic> json,
    required TextSelection selection,
    bool readOnly = false,
  }) {
    final document = quill.Document.fromJson(json);
    return QuillRichTextController(
      document: document,
      selection: selection,
      readOnly: readOnly,
    );
  }

  void _onQuillControllerChanged() {
    notifyListeners();
  }

  /// Access to underlying QuillController for adapter-specific operations
  quill.QuillController get quillController => _quillController;

  @override
  RichTextDocument get document => QuillRichTextDocument(_quillController.document);

  @override
  TextSelection get selection => _quillController.selection;

  @override
  set selection(TextSelection value) {
    _quillController.updateSelection(value, quill.ChangeSource.local);
  }

  @override
  bool get readOnly => _quillController.readOnly;

  // ========================================================================
  // Text Editing Operations
  // ========================================================================

  @override
  void replaceText(
    int index,
    int length,
    Object data,
    TextSelection? textSelection,
  ) {
    _quillController.replaceText(index, length, data, textSelection);
  }

  // ========================================================================
  // Content Extraction & Serialization
  // ========================================================================

  @override
  String getPlainText() {
    return _quillController.document.toPlainText();
  }

  @override
  List<dynamic> serialize() {
    return _quillController.document.toDelta().toJson();
  }

  // ========================================================================
  // Lifecycle
  // ========================================================================

  @override
  void dispose() {
    _quillController.removeListener(_onQuillControllerChanged);
    _quillController.dispose();
    super.dispose();
  }
}

/// Adapter implementation of [RichTextDocument] using flutter_quill Document.
class QuillRichTextDocument implements RichTextDocument {
  final quill.Document _document;

  QuillRichTextDocument(this._document);

  /// Factory constructor from JSON
  factory QuillRichTextDocument.fromJson(List<dynamic> json) {
    return QuillRichTextDocument(quill.Document.fromJson(json));
  }

  /// Factory constructor for empty document
  factory QuillRichTextDocument.empty() {
    return QuillRichTextDocument(quill.Document());
  }

  /// Access to underlying Quill Document for adapter-specific operations
  quill.Document get quillDocument => _document;

  @override
  int get length => _document.length;

  @override
  List<dynamic> toJson() {
    return _document.toDelta().toJson();
  }

  @override
  String toPlainText() {
    return _document.toPlainText();
  }
}
