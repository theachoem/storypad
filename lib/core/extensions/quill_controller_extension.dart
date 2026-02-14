import 'package:flutter_quill/flutter_quill.dart';

/// Extension methods on QuillController to prepare for abstraction layer migration.
///
/// These methods provide a forward-compatible API that matches the RichTextController
/// interface, making it easier to migrate to the abstraction layer in Phase 3.
extension QuillControllerExtension on QuillController {
  /// Serializes the document content to raw Delta JSON format.
  ///
  /// Returns the same format as `document.root.toDelta().toJson()`, but
  /// encapsulates the internal Document API access.
  ///
  /// This method will be replaced by RichTextController.serialize() in Phase 3.
  List<dynamic> serialize() {
    return document.toDelta().toJson();
  }

  /// Converts the document content to plain text.
  ///
  /// This is equivalent to calling `document.toPlainText()` but provides
  /// a forward-compatible API.
  String getPlainText() {
    return document.toPlainText();
  }
}
