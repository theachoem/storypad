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
// - [RichTextAdapter]: Unified adapter interface for all editor operations
// - [editorAdapter]: Global singleton instance for accessing the editor
//
// ## Architecture
//
// The singleton adapter pattern ensures complete decoupling:
// ```
// Business Logic
//     ↓ (calls editorAdapter.xxx)
// RichTextAdapter (interface)
//     ↓ (singleton instance)
// QuillRichTextAdapter (implementation)
//     ↓ (uses)
// flutter_quill package
// ```
//
// ## Usage
//
// ```dart
// // Create controller from JSON (database)
// final controller = editorAdapter.createController(
//   json: deltaJson,
//   selection: TextSelection.collapsed(offset: 0),
//   readOnly: false,
// );
//
// // Build editor widget
// editorAdapter.buildEditor(
//   context: context,
//   controller: controller,
//   readOnly: false,
//   ...
// );
//
// // Build toolbar widget
// editorAdapter.buildToolbar(
//   context: context,
//   controller: controller,
// );
//
// // Insert embeds
// editorAdapter.insertImage(
//   controller: controller,
//   imagePath: 'path/to/image.jpg',
// );
//
// // Serialize for storage
// final json = controller.serialize();
//
// // Access document
// final plainText = controller.document.toPlainText();
// ```

// Core abstractions
export 'rich_text_controller.dart';
export 'rich_text_document.dart';

// Adapter singleton (ONLY interface + instance, NOT concrete implementations)
export 'rich_text_adapter.dart';
