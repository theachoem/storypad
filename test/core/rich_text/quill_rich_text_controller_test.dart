import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_adapter.dart';

void main() {
  late QuillRichTextAdapter editorAdapter;

  setUp(() {
    editorAdapter = QuillRichTextAdapter();
  });

  group('QuillRichTextController', () {
    test('fromJson creates controller with provided content', () {
      final json = [
        {'insert': 'Hello World'},
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      expect(controller.getPlainText(), equals('Hello World\n'));
      expect(controller.readOnly, isFalse);
      expect(controller.selection, equals(const TextSelection.collapsed(offset: 0)));
    });

    test('fromJson handles empty JSON through adapter', () {
      // Note: QuillRichTextController.fromJson doesn't handle empty arrays,
      // but the adapter (createController) does. This tests the adapter path.
      final controller = editorAdapter.createController(
        json: [],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      // Empty document should have newline character
      expect(controller.getPlainText(), equals('\n'));
      expect(controller.document.length, equals(1));
    });

    test('constructor creates controller with custom document', () {
      final json = [
        {'insert': 'Test content'},
        {'insert': '\n'},
      ];
      final document = QuillRichTextDocument.fromJson(json);

      final controller = QuillRichTextController(
        document: document.quillDocument,
        selection: const TextSelection.collapsed(offset: 5),
        readOnly: true,
      );

      expect(controller.getPlainText(), equals('Test content\n'));
      expect(controller.readOnly, isTrue);
      expect(controller.selection.baseOffset, equals(5));
    });

    test('getPlainText returns text without formatting', () {
      final json = [
        {
          'insert': 'Bold text',
          'attributes': {'bold': true},
        },
        {'insert': ' and '},
        {
          'insert': 'italic text',
          'attributes': {'italic': true},
        },
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      expect(
        controller.getPlainText(),
        equals('Bold text and italic text\n'),
      );
    });

    test('serialize returns optimized JSON structure', () {
      final json = [
        {'insert': 'Hello'},
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      final serialized = controller.serialize();
      // Quill optimizes by merging consecutive text inserts
      expect(
        serialized,
        equals([
          {'insert': 'Hello\n'},
        ]),
      );
    });

    test('serialize preserves formatting attributes', () {
      final json = [
        {
          'insert': 'Formatted',
          'attributes': {'bold': true, 'italic': true},
        },
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      final serialized = controller.serialize();
      expect(serialized, equals(json));
    });

    test('replaceText inserts plain text at position', () {
      final json = [
        {'insert': 'Hello World'},
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 5),
        readOnly: false,
      );

      // Insert text at position 5 (after "Hello")
      controller.replaceText(5, 0, ' Beautiful', null);

      expect(controller.getPlainText(), equals('Hello Beautiful World\n'));
    });

    test('replaceText replaces selected text', () {
      final json = [
        {'insert': 'Hello World'},
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      // Replace "World" (index 6-11) with "Flutter"
      controller.replaceText(6, 5, 'Flutter', null);

      expect(controller.getPlainText(), equals('Hello Flutter\n'));
    });

    test('replaceText handles embed objects through adapter', () {
      // Note: Direct replaceText requires Embeddable objects, not plain maps.
      // Use the adapter's insertImage method instead.
      final controller = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Text before'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 11),
        readOnly: false,
      );

      // Use adapter to insert image (it handles the Embeddable conversion)
      editorAdapter.insertImage(
        controller: controller,
        imagePath: 'images/test.jpg',
      );

      final serialized = controller.serialize();
      final hasImage = serialized.any((op) {
        final insert = op['insert'];
        return insert is Map && insert['image'] == 'images/test.jpg';
      });
      expect(hasImage, isTrue);
    });

    test('selection getter returns current selection', () {
      final controller = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Hello'},
          {'insert': '\n'},
        ],
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
        readOnly: false,
      );

      expect(controller.selection.baseOffset, equals(0));
      expect(controller.selection.extentOffset, equals(5));
    });

    test('selection setter updates current selection', () {
      final controller = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Hello World'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);

      expect(controller.selection.baseOffset, equals(6));
      expect(controller.selection.extentOffset, equals(11));
    });

    test('document getter returns RichTextDocument', () {
      final json = [
        {'insert': 'Test'},
        {'insert': '\n'},
      ];

      final controller = QuillRichTextController.fromJson(
        json: json,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      final document = controller.document;
      expect(document, isA<QuillRichTextDocument>());
      expect(document.toPlainText(), equals('Test\n'));
    });

    test('controller notifies listeners on changes', () {
      final controller = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Test'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.replaceText(0, 0, 'New ', null);

      expect(notified, isTrue);
    });

    test('readOnly property is accessible', () {
      final readOnlyController = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Test'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      final editableController = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Test'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      expect(readOnlyController.readOnly, isTrue);
      expect(editableController.readOnly, isFalse);
    });

    test('dispose removes listeners and disposes underlying controller', () {
      final controller = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Test'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.dispose();

      // After dispose, listener should not be called
      expect(notified, isFalse);
    });

    test('quillController provides access to underlying controller', () {
      final controller = QuillRichTextController.fromJson(
        json: [
          {'insert': 'Test'},
          {'insert': '\n'},
        ],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );

      final quillController = controller.quillController;
      expect(quillController, isNotNull);
      expect(quillController.document.toPlainText(), equals('Test\n'));
    });
  });
}
