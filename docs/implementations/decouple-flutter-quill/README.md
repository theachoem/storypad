# Rich Text Abstraction Layer

This directory contains the abstraction layer that decouples StoryPad from flutter_quill.

## Purpose

Enable swapping rich text editor implementations without rewriting the entire application.

## Structure

### Core Abstractions (`lib/core/rich_text/`)

- **`rich_text_controller.dart`**: Interface for editor control operations
- **`rich_text_document.dart`**: Interface for document representation
- **`rich_text_serializer.dart`**: Interface for format conversion
- **`rich_text_embed_builder.dart`**: Interface for custom embeds

### Adapters (`lib/core/rich_text/adapters/`)

- **`quill_adapter.dart`**: Implements abstractions using flutter_quill
- **`quill_serializer.dart`**: Wraps Delta JSON processing
- **`quill_embed_builder_adapter.dart`**: Bridges custom embed builders

## Import Pattern

```dart
// Import abstractions (no flutter_quill dependency)
import 'package:storypad/core/rich_text/rich_text.dart';

// Use abstraction
RichTextController controller = QuillRichTextController.fromJson(...);
```

## Migration Progress

- [x] Phase 1: Create abstraction layer ✅
- [ ] Phase 2: Migrate services to use abstractions
- [ ] Phase 3: Migrate core objects
- [ ] Phase 4: Remove internal API usage
- [ ] Phase 5: Create UI adapters
- [ ] Phase 6: Migrate custom embeds
- [ ] Phase 7: Data format migration (optional)

## Design Principles

1. **Separation of Concerns**: Business logic uses abstractions, adapters handle implementation
2. **Backward Compatibility**: Maintain Delta JSON format during migration
3. **Gradual Migration**: Phase-by-phase to minimize risk
4. **Single Responsibility**: Each adapter has one job

## Example Usage

```dart
// Create controller
final controller = QuillRichTextController.fromJson(
  json: storyPage.body ?? [],
  selection: TextSelection.collapsed(offset: 0),
  readOnly: false,
);

// Format text
controller.formatSelection('bold', true);
controller.insertText('Hello World');

// Serialize
final json = controller.serialize();

// Convert to plain text
final serializer = QuillSerializer();
final plainText = serializer.toPlainText(json);
```

## Testing

Abstractions can be mocked for unit testing:

```dart
class MockRichTextController extends Mock implements RichTextController {}

test('example', () {
  final mockController = MockRichTextController();
  when(mockController.serialize()).thenReturn([...]);
  // ...
});
```
