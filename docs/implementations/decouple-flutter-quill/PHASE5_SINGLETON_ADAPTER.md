# Phase 5: Singleton Adapter Pattern - Complete Decoupling

## Overview

This phase eliminates ALL coupling to flutter_quill by introducing a unified `RichTextAdapter` interface accessed via a singleton `editorAdapter` instance. Business logic will call `editorAdapter.localizationsDelegates`, `editorAdapter.buildEditor()`, `editorAdapter.insertImage()`, etc., instead of importing concrete flutter_quill types.

## Current Problems

### 1. Concrete Types Exported from Abstraction Layer

rich_text.dart currently exports:

- `QuillRichTextController` (concrete class)
- `QuillSerializer` (concrete class)
- `QuillLocalizations` (concrete class)
- `QuillEmbedHelper` (concrete class)

Business logic uses these directly, creating tight coupling.

### 2. Direct Builder Imports

- sp_pages_toolbar.dart imports quill_toolbar_builder.dart
- story_pages_builder.dart imports quill_editor_builder.dart

### 3. Exposed Implementation Details

- app.dart uses `QuillLocalizations.delegate`
- `story_page_objects_map.dart` calls `QuillRichTextController.fromJson()`
- Bottom sheets use `QuillEmbedHelper.insertImage()` / `insertAudio()`

### 4. Files Affected (8 Total)

1. app.dart - Uses `QuillLocalizations.delegate`
2. sp_pages_toolbar.dart - Imports builder
3. story_pages_builder.dart - Imports builder
4. sp_image_picker_bottom_sheet.dart - Uses `QuillEmbedHelper`
5. sp_voice_recording_sheet.dart - Uses `QuillEmbedHelper`
6. story_page_objects_map.dart - Uses `QuillRichTextController`
7. story_content_pages_to_document_service.dart - Uses `QuillRichTextDocument`
8. story_db_model.dart - Imports unused `quill_delta`

## Solution: Singleton Adapter Pattern

### Architecture

```
Business Logic
     ↓ (calls editorAdapter.xxx)
RichTextAdapter (abstract interface)
     ↓ (singleton instance)
QuillRichTextAdapter (implementation)
     ↓ (uses)
flutter_quill package
```

### Key Principle

**Before**: Business logic imports concrete types

```dart
import 'package:storypad/core/rich_text/rich_text.dart';

// Exposes: QuillRichTextController, QuillLocalizations, etc.
QuillLocalizations.delegate
QuillRichTextController.fromJson(...)
QuillEmbedHelper.insertImage(...)
```

**After**: Business logic uses singleton instance

```dart
import 'package:storypad/core/rich_text/rich_text.dart';

// Only exposes: editorAdapter + abstract interfaces
editorAdapter.localizationsDelegates
editorAdapter.createController(...)
editorAdapter.insertImage(...)
```

---

## Implementation Steps

### Step 1: Create Abstract RichTextAdapter Interface

**File**: `lib/core/rich_text/rich_text_adapter.dart` (NEW)

````dart
import 'package:flutter/widgets.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

/// Abstract interface for rich text editor adapter.
///
/// This interface isolates all implementation-specific APIs behind a clean boundary.
/// Business logic only interacts with this adapter, never with concrete implementations.
abstract class RichTextAdapter {
  // ========================================================================
  // Localization
  // ========================================================================

  /// Returns localization delegates required by the editor.
  ///
  /// Add these to MaterialApp's localizationsDelegates:
  /// ```dart
  /// MaterialApp(
  ///   localizationsDelegates: [
  ///     ...otherDelegates,
  ///     ...editorAdapter.localizationsDelegates,
  ///   ],
  /// )
  /// ```
  List<LocalizationsDelegate> get localizationsDelegates;

  // ========================================================================
  // Widget Builders
  // ========================================================================

  /// Builds the rich text editor widget.
  Widget buildEditor({
    required BuildContext context,
    required RichTextController controller,
    required bool readOnly,
    FocusNode? focusNode,
    ScrollController? scrollController,
    bool? showCursor,
    bool? expands,
    EdgeInsets? padding,
    Map<String, dynamic>? customStyles,
  });

  /// Builds the rich text toolbar widget.
  Widget buildToolbar({
    required BuildContext context,
    required RichTextController controller,
  });

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Creates a RichTextController from JSON data.
  ///
  /// [json]: Delta JSON from database (List<dynamic>)
  /// [selection]: Initial cursor position
  /// [readOnly]: Whether the editor is read-only
  RichTextController createController({
    required List<dynamic> json,
    required TextSelection selection,
    required bool readOnly,
  });

  /// Creates a RichTextController with empty content.
  RichTextController createEmptyController({
    required bool readOnly,
  });

  /// Creates a RichTextDocument from JSON data.
  RichTextDocument createDocument({
    required List<dynamic> json,
  });

  /// Creates an empty RichTextDocument.
  RichTextDocument createEmptyDocument();

  // ========================================================================
  // Embed Operations
  // ========================================================================

  /// Inserts an image embed at the current cursor position.
  ///
  /// [controller]: The rich text controller
  /// [imagePath]: Relative path to the image file
  void insertImage({
    required RichTextController controller,
    required String imagePath,
  });

  /// Inserts an audio embed at the current cursor position.
  ///
  /// [controller]: The rich text controller
  /// [audioPath]: Relative path to the audio file
  void insertAudio({
    required RichTextController controller,
    required String audioPath,
  });
}

// Import the implementation
import 'package:storypad/core/rich_text/flutter_quill/quill_rich_text_adapter.dart';

/// Global singleton instance for rich text editor adapter.
///
/// Business logic should ONLY interact with the editor through this instance.
///
/// Example usage:
/// ```dart
/// // In app.dart:
/// localizationsDelegates: editorAdapter.localizationsDelegates
///
/// // In editor view:
/// editorAdapter.buildEditor(context: context, controller: controller, ...)
///
/// // In bottom sheet:
/// editorAdapter.insertImage(controller: controller, imagePath: path)
/// ```
final RichTextAdapter editorAdapter = QuillRichTextAdapter();
````

---

### Step 2: Implement QuillRichTextAdapter

**File**: `lib/core/rich_text/flutter_quill/quill_rich_text_adapter.dart` (NEW)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:meta/meta.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_adapter.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_editor_builder.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_toolbar_builder.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

/// Flutter Quill implementation of RichTextAdapter.
@visibleForTesting
class QuillRichTextAdapter implements RichTextAdapter {
  @override
  List<LocalizationsDelegate> get localizationsDelegates {
    return [quill.FlutterQuillLocalizations.delegate];
  }

  @override
  Widget buildEditor({
    required BuildContext context,
    required RichTextController controller,
    required bool readOnly,
    FocusNode? focusNode,
    ScrollController? scrollController,
    bool? showCursor,
    bool? expands,
    EdgeInsets? padding,
    Map<String, dynamic>? customStyles,
  }) {
    return buildQuillEditor(
      context: context,
      controller: controller,
      readOnly: readOnly,
      focusNode: focusNode,
      scrollController: scrollController,
      showCursor: showCursor,
      expands: expands,
      padding: padding,
      customStyles: customStyles,
    );
  }

  @override
  Widget buildToolbar({
    required BuildContext context,
    required RichTextController controller,
  }) {
    return buildQuillToolbar(
      context: context,
      controller: controller,
    );
  }

  @override
  RichTextController createController({
    required List<dynamic> json,
    required TextSelection selection,
    required bool readOnly,
  }) {
    return QuillRichTextController.fromJson(
      json: json,
      selection: selection,
      readOnly: readOnly,
    );
  }

  @override
  RichTextController createEmptyController({
    required bool readOnly,
  }) {
    return QuillRichTextController(
      quillController: quill.QuillController.basic(
        configurations: quill.QuillControllerConfigurations(
          readOnly: readOnly,
        ),
      ),
    );
  }

  @override
  RichTextDocument createDocument({
    required List<dynamic> json,
  }) {
    return QuillRichTextDocument.fromJson(json);
  }

  @override
  RichTextDocument createEmptyDocument() {
    return QuillRichTextDocument.empty();
  }

  @override
  void insertImage({
    required RichTextController controller,
    required String imagePath,
  }) {
    if (controller is! QuillRichTextController) {
      throw ArgumentError('Controller must be a QuillRichTextController');
    }

    final quillController = controller.quillController;
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;

    quillController.replaceText(
      index,
      length,
      quill.BlockEmbed.image(imagePath),
      null,
    );
    quillController.moveCursorToPosition(index + 1);
  }

  @override
  void insertAudio({
    required RichTextController controller,
    required String audioPath,
  }) {
    if (controller is! QuillRichTextController) {
      throw ArgumentError('Controller must be a QuillRichTextController');
    }

    final quillController = controller.quillController;
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;

    final audioEmbed = quill.BlockEmbed('audio', audioPath);

    quillController.replaceText(
      index,
      length,
      audioEmbed,
      null,
    );
    quillController.moveCursorToPosition(index + 1);
  }
}
```

---

### Step 3: Update Exports in rich_text.dart

**File**: rich_text.dart

**REMOVE these exports**:

```dart
// DELETE THESE LINES:
export 'flutter_quill/quill_adapter.dart';
export 'flutter_quill/quill_serializer.dart';
export 'flutter_quill/quill_embed_builder_adapter.dart';
export 'flutter_quill/quill_localizations.dart';
export 'flutter_quill/quill_controller_extension.dart';
export 'flutter_quill/quill_embed_helper.dart';
```

**KEEP/ADD these exports**:

```dart
// Core abstractions
export 'rich_text_controller.dart';
export 'rich_text_document.dart';
export 'rich_text_serializer.dart';
export 'rich_text_embed_builder.dart';

// Adapter singleton (ONLY interface + instance, NOT concrete implementations)
export 'rich_text_adapter.dart';
```

---

### Step 4: Update Business Logic Files (8 Files)

#### 4.1. app.dart

**Change**:

```dart
// BEFORE:
import 'package:flutter/material.dart';
import 'package:storypad/core/rich_text/rich_text.dart';
// ...
localizationsDelegates: [
  ...EasyLocalization.of(context)!.delegates,
  DefaultCupertinoLocalizations.delegate,
  DefaultMaterialLocalizations.delegate,
  DefaultWidgetsLocalizations.delegate,
  QuillLocalizations.delegate,
],

// AFTER:
import 'package:flutter/material.dart';
import 'package:storypad/core/rich_text/rich_text.dart';
// ...
localizationsDelegates: [
  ...EasyLocalization.of(context)!.delegates,
  DefaultCupertinoLocalizations.delegate,
  DefaultMaterialLocalizations.delegate,
  DefaultWidgetsLocalizations.delegate,
  ...editorAdapter.localizationsDelegates,
],
```

#### 4.2. sp_pages_toolbar.dart

**Change**:

```dart
// BEFORE:
import 'package:storypad/core/rich_text/flutter_quill/quill_toolbar_builder.dart';
// ...
buildQuillToolbar(
  context: context,
  controller: controller,
)

// AFTER:
import 'package:storypad/core/rich_text/rich_text.dart';
// ...
editorAdapter.buildToolbar(
  context: context,
  controller: controller,
)
```

#### 4.3. story_pages_builder.dart

**Change**:

```dart
// BEFORE:
import 'package:storypad/core/rich_text/flutter_quill/quill_editor_builder.dart';
// ...
buildQuillEditor(
  context: context,
  controller: page.bodyController,
  readOnly: readOnly,
  // ... other params
)

// AFTER:
import 'package:storypad/core/rich_text/rich_text.dart';
// ...
editorAdapter.buildEditor(
  context: context,
  controller: page.bodyController,
  readOnly: readOnly,
  // ... other params
)
```

#### 4.4. sp_image_picker_bottom_sheet.dart

**Change**:

```dart
// BEFORE:
QuillEmbedHelper.insertImage(
  controller: controller,
  imagePath: tookAsset.relativeLocalFilePath,
);

// AFTER:
editorAdapter.insertImage(
  controller: controller,
  imagePath: tookAsset.relativeLocalFilePath,
);
```

#### 4.5. sp_voice_recording_sheet.dart

**Change**:

```dart
// BEFORE:
QuillEmbedHelper.insertAudio(
  controller: controller,
  audioPath: savedAsset.relativeLocalFilePath,
);

// AFTER:
editorAdapter.insertAudio(
  controller: controller,
  audioPath: savedAsset.relativeLocalFilePath,
);
```

#### 4.6. story_page_objects_map.dart

**Change**:

```dart
// BEFORE:
bodyController = QuillRichTextController.fromJson(
  json: page.body ?? [],
  selection: const TextSelection.collapsed(offset: 0),
  readOnly: false,
);

// AFTER:
bodyController = editorAdapter.createController(
  json: page.body ?? [],
  selection: const TextSelection.collapsed(offset: 0),
  readOnly: false,
);
```

#### 4.7. story_content_pages_to_document_service.dart

**Change**:

```dart
// BEFORE:
final document = QuillRichTextDocument.fromJson(page.body ?? []);
final emptyDoc = QuillRichTextDocument.empty();

// AFTER:
final document = editorAdapter.createDocument(json: page.body ?? []);
final emptyDoc = editorAdapter.createEmptyDocument();
```

#### 4.8. story_db_model.dart

**Change**:

```dart
// BEFORE:
import 'package:flutter_quill/quill_delta.dart';
// ...
// List: Returns JSON-serializable version of quill delta.
final List<dynamic>? body;

// AFTER:
// (Remove import)
// ...
// List: Returns JSON-serializable rich text content.
final List<dynamic>? body;
```

---

## Verification Checklist

### 1. No Concrete Type Imports

```bash
grep -r "QuillRichTextController\|QuillLocalizations\|QuillEmbedHelper\|buildQuill" lib/ --include="*.dart" | grep -v "lib/core/rich_text/flutter_quill/" | grep -v "legacy"
```

**Expected**: 0 matches

### 2. No Direct Builder Imports

```bash
grep -r "import.*flutter_quill/quill.*builder" lib/ --include="*.dart" | grep -v "lib/core/rich_text/flutter_quill/"
```

**Expected**: 0 matches

### 3. Compilation Passes

```bash
dart analyze lib/
```

**Expected**: 0 errors

### 4. Integration Test

- [ ] Editor loads and displays content
- [ ] Toolbar shows and works
- [ ] Image picker inserts images
- [ ] Voice recorder inserts audio
- [ ] Localization displays properly

---

## Benefits

✅ **Zero coupling** - Business logic never uses concrete flutter_quill types  
✅ **Clean API** - Everything through `editorAdapter.xxx`  
✅ **Easy swap** - Replace impl by changing singleton  
✅ **Testable** - Mock `RichTextAdapter` interface  
✅ **Clear boundaries** - Strict separation of concerns
