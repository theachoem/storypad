import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

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
  // Formatting Operations
  // ========================================================================

  @override
  void formatSelection(String attributeKey, dynamic value) {
    final attribute = _getAttributeFromKey(attributeKey, value);
    if (attribute != null) {
      _quillController.formatSelection(attribute);
    }
  }

  @override
  void removeFormat(String attributeKey) {
    final attribute = _getAttributeFromKey(attributeKey, null);
    if (attribute != null) {
      _quillController.formatSelection(attribute);
    }
  }

  @override
  Map<String, dynamic> getSelectionStyle() {
    final style = _quillController.getSelectionStyle();
    return _convertAttributesToMap(style.attributes);
  }

  @override
  List<Map<String, dynamic>> getAllSelectionStyles() {
    final styles = _quillController.getAllSelectionStyles();
    return styles.map((style) => _convertAttributesToMap(style.attributes)).toList();
  }

  /// Converts Quill attribute key to actual Attribute instance
  quill.Attribute? _getAttributeFromKey(String key, dynamic value) {
    switch (key) {
      case 'bold':
        return value == true ? quill.Attribute.bold : quill.Attribute.clone(quill.Attribute.bold, null);
      case 'italic':
        return value == true ? quill.Attribute.italic : quill.Attribute.clone(quill.Attribute.italic, null);
      case 'underline':
        return value == true ? quill.Attribute.underline : quill.Attribute.clone(quill.Attribute.underline, null);
      case 'strike':
        return value == true
            ? quill.Attribute.strikeThrough
            : quill.Attribute.clone(quill.Attribute.strikeThrough, null);
      case 'color':
        return value != null
            ? quill.Attribute.fromKeyValue('color', value)
            : quill.Attribute.clone(quill.Attribute.color, null);
      case 'background':
        return value != null
            ? quill.Attribute.fromKeyValue('background', value)
            : quill.Attribute.clone(quill.Attribute.background, null);
      case 'link':
        return value != null
            ? quill.Attribute.fromKeyValue('link', value.toString())
            : quill.Attribute.clone(quill.Attribute.link, null);
      case 'list':
        if (value == 'bullet') return quill.Attribute.ul;
        if (value == 'ordered') return quill.Attribute.ol;
        if (value == 'checked') return quill.Attribute.checked;
        if (value == 'unchecked') return quill.Attribute.unchecked;
        return quill.Attribute.clone(quill.Attribute.ul, null);
      case 'align':
        if (value == 'left') return quill.Attribute.leftAlignment;
        if (value == 'center') return quill.Attribute.centerAlignment;
        if (value == 'right') return quill.Attribute.rightAlignment;
        if (value == 'justify') return quill.Attribute.justifyAlignment;
        return quill.Attribute.clone(quill.Attribute.leftAlignment, null);
      case 'header':
        if (value == 1) return quill.Attribute.h1;
        if (value == 2) return quill.Attribute.h2;
        if (value == 3) return quill.Attribute.h3;
        return quill.Attribute.clone(quill.Attribute.h1, null);
      case 'blockquote':
        return value == true ? quill.Attribute.blockQuote : quill.Attribute.clone(quill.Attribute.blockQuote, null);
      case 'code-block':
        return value == true ? quill.Attribute.codeBlock : quill.Attribute.clone(quill.Attribute.codeBlock, null);
      case 'indent':
        return value != null
            ? quill.Attribute.getIndentLevel(value)
            : quill.Attribute.clone(quill.Attribute.indentL1, null);
      default:
        return null;
    }
  }

  /// Converts Quill attributes to generic Map format
  Map<String, dynamic> _convertAttributesToMap(Map<String, quill.Attribute> attributes) {
    final result = <String, dynamic>{};
    for (final entry in attributes.entries) {
      result[entry.key] = entry.value.value;
    }
    return result;
  }

  // ========================================================================
  // Content Extraction
  // ========================================================================

  @override
  String getPlainText() {
    return _quillController.document.toPlainText();
  }

  @override
  String toMarkdown() {
    // Use existing QuillDeltaToPlainTextService for markdown conversion
    // This will be refactored in Phase 2 to use RichTextSerializer
    return _quillController.document.toDelta().toJson().toString();
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
  bool get isEmpty => _document.isEmpty();

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  List<dynamic> toJson() {
    return _document.toDelta().toJson();
  }

  @override
  String toPlainText() {
    return _document.toPlainText();
  }

  @override
  String toMarkdown() {
    // Will be implemented with RichTextSerializer in Phase 2
    return _document.toPlainText();
  }
}
