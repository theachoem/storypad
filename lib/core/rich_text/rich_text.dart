// Rich Text Abstraction Layer for StoryPad
//
// This library provides a platform-agnostic abstraction over rich text editing,
// allowing the application to work with different rich text editor implementations
// without tight coupling to a specific library.
//
// ## Core Abstractions
//
// - [RichTextController]: Interface for controlling a rich text editor
// - [RichTextDocument]: Interface for document representation
// - [RichTextSerializer]: Interface for format conversion
// - [RichTextEmbedBuilder]: Interface for custom content embeds
//
// ## Current Implementation
//
// The current implementation uses flutter_quill via adapters:
// - [QuillRichTextController]: Wraps QuillController
// - [QuillRichTextDocument]: Wraps Quill Document
// - [QuillSerializer]: Wraps Delta JSON processing
// - [QuillEmbedBuilderAdapter]: Bridges custom embeds
//
// ## Usage
//
// ```dart
// // Create controller from JSON (database)
// final controller = QuillRichTextController.fromJson(
//   json: deltaJson,
//   selection: TextSelection.collapsed(offset: 0),
//   readOnly: false,
// );
//
// // Format text
// controller.formatSelection('bold', true);
//
// // Insert embed
// controller.insertEmbed('image', 'path/to/image.jpg');
//
// // Serialize for storage
// final json = controller.serialize();
//
// // Convert to plain text
// final serializer = QuillSerializer();
// final plainText = serializer.toPlainText(json);
// ```

// Core abstractions
export 'rich_text_controller.dart';
export 'rich_text_document.dart';
export 'rich_text_serializer.dart';
export 'rich_text_embed_builder.dart';

// Quill adapter implementation
export 'adapters/quill_adapter.dart';
export 'adapters/quill_serializer.dart';
export 'adapters/quill_embed_builder_adapter.dart';
