import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

void main() {
  group('QuillRichTextAdapter', () {
    late QuillRichTextAdapter adapter;

    setUp(() {
      adapter = QuillRichTextAdapter();
    });

    group('localizationsDelegates', () {
      test('returns non-empty list of delegates', () {
        final delegates = adapter.localizationsDelegates;

        expect(delegates, isNotEmpty);
        expect(delegates, isA<List<LocalizationsDelegate>>());
      });

      test('delegates are accessible without errors', () {
        expect(() => adapter.localizationsDelegates, returnsNormally);
      });
    });

    group('createController()', () {
      test('creates controller from valid JSON', () {
        final json = [
          {'insert': 'Test content'},
          {'insert': '\n'},
        ];

        final controller = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        expect(controller, isA<RichTextController>());
        expect(controller, isA<QuillRichTextController>());
        expect(controller.getPlainText(), equals('Test content\n'));
      });

      test('creates controller with correct selection', () {
        final json = [
          {'insert': 'Test'},
          {'insert': '\n'},
        ];

        final controller = adapter.createController(
          json: json,
          selection: const TextSelection(baseOffset: 0, extentOffset: 4),
          readOnly: false,
        );

        expect(controller.selection.baseOffset, equals(0));
        expect(controller.selection.extentOffset, equals(4));
      });

      test('creates controller with correct readOnly state', () {
        final json = [
          {'insert': 'Test'},
          {'insert': '\n'},
        ];

        final readOnlyController = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );

        final editableController = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        expect(readOnlyController.readOnly, isTrue);
        expect(editableController.readOnly, isFalse);
      });

      test('handles empty JSON by creating empty controller', () {
        final controller = adapter.createController(
          json: [],
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        expect(controller, isNotNull);
        expect(controller.getPlainText(), equals('\n'));
      });

      test('creates controller with formatted text', () {
        final json = [
          {
            'insert': 'Bold text',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ];

        final controller = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        expect(controller.getPlainText(), equals('Bold text\n'));
        expect(controller.serialize(), equals(json));
      });

      test('creates controller with embeds', () {
        final json = [
          {'insert': 'Text'},
          {
            'insert': {'image': 'images/test.jpg'},
          },
          {'insert': '\n'},
        ];

        final controller = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        final serialized = controller.serialize();
        expect(serialized[1]['insert'], equals({'image': 'images/test.jpg'}));
      });
    });

    group('createEmptyController()', () {
      test('creates empty controller', () {
        final controller = adapter.createEmptyController(readOnly: false);

        expect(controller, isA<RichTextController>());
        expect(controller.getPlainText(), equals('\n'));
        expect(controller.readOnly, isFalse);
      });

      test('creates empty read-only controller', () {
        final controller = adapter.createEmptyController(readOnly: true);

        expect(controller.readOnly, isTrue);
      });

      test('empty controller has valid document', () {
        final controller = adapter.createEmptyController(readOnly: false);

        expect(controller.document, isNotNull);
        expect(controller.document.length, equals(1));
      });

      test('empty controller can be serialized', () {
        final controller = adapter.createEmptyController(readOnly: false);
        final json = controller.serialize();

        expect(json, isA<List>());
        expect(json, isNotEmpty);
      });
    });

    group('createDocument()', () {
      test('creates document from valid JSON', () {
        final json = [
          {'insert': 'Document content'},
          {'insert': '\n'},
        ];

        final document = adapter.createDocument(json: json);

        expect(document, isA<RichTextDocument>());
        expect(document, isA<QuillRichTextDocument>());
        expect(document.toPlainText(), equals('Document content\n'));
      });

      test('handles empty JSON by creating empty document', () {
        final document = adapter.createDocument(json: []);

        expect(document, isNotNull);
        expect(document.toPlainText(), equals('\n'));
      });

      test('creates document with formatted content', () {
        final json = [
          {
            'insert': 'Formatted',
            'attributes': {'bold': true, 'italic': true},
          },
          {'insert': '\n'},
        ];

        final document = adapter.createDocument(json: json);

        expect(document.toJson(), equals(json));
      });

      test('creates document with embeds', () {
        final json = [
          {
            'insert': {'image': 'images/photo.jpg'},
          },
          {'insert': '\n'},
        ];

        final document = adapter.createDocument(json: json);

        final serialized = document.toJson();
        expect(serialized[0]['insert'], equals({'image': 'images/photo.jpg'}));
      });
    });

    group('createEmptyDocument()', () {
      test('creates empty document', () {
        final document = adapter.createEmptyDocument();

        expect(document, isA<RichTextDocument>());
        expect(document.toPlainText(), equals('\n'));
      });

      test('empty document has correct length', () {
        final document = adapter.createEmptyDocument();

        expect(document.length, equals(1));
      });

      test('empty document can be serialized', () {
        final document = adapter.createEmptyDocument();
        final json = document.toJson();

        expect(json, isA<List>());
        expect(json, isNotEmpty);
      });
    });

    group('insertImage()', () {
      test('inserts image at cursor position', () {
        final controller = adapter.createController(
          json: [
            {'insert': 'Text before'},
            {'insert': '\n'},
          ],
          selection: const TextSelection.collapsed(offset: 11),
          readOnly: false,
        );

        adapter.insertImage(
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

      test('replaces selected text with image', () {
        final controller = adapter.createController(
          json: [
            {'insert': 'Replace this text'},
            {'insert': '\n'},
          ],
          selection: const TextSelection(baseOffset: 0, extentOffset: 7),
          readOnly: false,
        );

        adapter.insertImage(
          controller: controller,
          imagePath: 'images/replacement.jpg',
        );

        final plainText = controller.getPlainText();
        expect(plainText, contains('this text'));
        expect(plainText, isNot(contains('Replace')));
      });

      test('moves cursor after inserted image', () {
        final controller = adapter.createController(
          json: [
            {'insert': 'Test'},
            {'insert': '\n'},
          ],
          selection: const TextSelection.collapsed(offset: 4),
          readOnly: false,
        );

        adapter.insertImage(
          controller: controller,
          imagePath: 'images/test.jpg',
        );

        // Cursor should be after the image (position 5: "Test" + image)
        expect(controller.selection.baseOffset, equals(5));
      });

      test('throws ArgumentError if controller is not QuillRichTextController', () {
        final mockController = _MockRichTextController();

        expect(
          () => adapter.insertImage(
            controller: mockController,
            imagePath: 'images/test.jpg',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles various image paths correctly', () {
        final testPaths = [
          'images/photo.jpg',
          'images/subfolder/image.png',
          'assets/img/picture.gif',
        ];

        for (final path in testPaths) {
          final controller = adapter.createEmptyController(readOnly: false);

          adapter.insertImage(
            controller: controller,
            imagePath: path,
          );

          final serialized = controller.serialize();
          final hasImage = serialized.any((op) {
            final insert = op['insert'];
            return insert is Map && insert['image'] == path;
          });

          expect(hasImage, isTrue, reason: 'Failed for path: $path');
        }
      });
    });

    group('insertAudio()', () {
      test('inserts audio at cursor position', () {
        final controller = adapter.createController(
          json: [
            {'insert': 'Text before'},
            {'insert': '\n'},
          ],
          selection: const TextSelection.collapsed(offset: 11),
          readOnly: false,
        );

        adapter.insertAudio(
          controller: controller,
          audioPath: 'audio/recording.m4a',
        );

        final serialized = controller.serialize();
        final hasAudio = serialized.any((op) {
          final insert = op['insert'];
          return insert is Map && insert['audio'] == 'audio/recording.m4a';
        });

        expect(hasAudio, isTrue);
      });

      test('replaces selected text with audio', () {
        final controller = adapter.createController(
          json: [
            {'insert': 'Replace this'},
            {'insert': '\n'},
          ],
          selection: const TextSelection(baseOffset: 0, extentOffset: 7),
          readOnly: false,
        );

        adapter.insertAudio(
          controller: controller,
          audioPath: 'audio/voice.m4a',
        );

        final plainText = controller.getPlainText();
        expect(plainText, contains('this'));
        expect(plainText, isNot(contains('Replace')));
      });

      test('moves cursor after inserted audio', () {
        final controller = adapter.createController(
          json: [
            {'insert': 'Test'},
            {'insert': '\n'},
          ],
          selection: const TextSelection.collapsed(offset: 4),
          readOnly: false,
        );

        adapter.insertAudio(
          controller: controller,
          audioPath: 'audio/test.m4a',
        );

        // Cursor should be after the audio (position 5: "Test" + audio)
        expect(controller.selection.baseOffset, equals(5));
      });

      test('throws ArgumentError if controller is not QuillRichTextController', () {
        final mockController = _MockRichTextController();

        expect(
          () => adapter.insertAudio(
            controller: mockController,
            audioPath: 'audio/test.m4a',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles various audio paths correctly', () {
        final testPaths = [
          'audio/recording.m4a',
          'audio/subfolder/voice.wav',
          'assets/sounds/music.mp3',
        ];

        for (final path in testPaths) {
          final controller = adapter.createEmptyController(readOnly: false);

          adapter.insertAudio(
            controller: controller,
            audioPath: path,
          );

          final serialized = controller.serialize();
          final hasAudio = serialized.any((op) {
            final insert = op['insert'];
            return insert is Map && insert['audio'] == path;
          });

          expect(hasAudio, isTrue, reason: 'Failed for path: $path');
        }
      });
    });

    group('global editorAdapter singleton', () {
      test('is a QuillRichTextAdapter instance', () {
        expect(editorAdapter, isA<QuillRichTextAdapter>());
        expect(editorAdapter, isA<RichTextAdapter>());
      });

      test('provides all adapter methods', () {
        expect(editorAdapter.localizationsDelegates, isNotEmpty);
        expect(() => editorAdapter.createEmptyController(readOnly: false), returnsNormally);
        expect(() => editorAdapter.createEmptyDocument(), returnsNormally);
      });

      test('is accessible without instantiation', () {
        final controller = editorAdapter.createController(
          json: [
            {'insert': 'Test'},
            {'insert': '\n'},
          ],
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        expect(controller, isNotNull);
        expect(controller.getPlainText(), equals('Test\n'));
      });
    });

    group('integration tests', () {
      test('controller and document work together correctly', () {
        final json = [
          {'insert': 'Integration test'},
          {'insert': '\n'},
        ];

        final controller = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        final document = controller.document;

        expect(document.toPlainText(), equals(controller.getPlainText()));
        expect(document.toJson(), equals(controller.serialize()));
      });

      test('can modify controller and document remains in sync', () {
        final controller = adapter.createEmptyController(readOnly: false);

        controller.replaceText(0, 0, 'New text', null);

        expect(controller.document.toPlainText(), contains('New text'));
      });

      test('inserting image and then serializing maintains data', () {
        final controller = adapter.createEmptyController(readOnly: false);

        adapter.insertImage(
          controller: controller,
          imagePath: 'images/test.jpg',
        );

        final json = controller.serialize();
        final newController = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        final hasImage = newController.serialize().any((op) {
          final insert = op['insert'];
          return insert is Map && insert['image'] == 'images/test.jpg';
        });

        expect(hasImage, isTrue);
      });

      test('inserting audio and then serializing maintains data', () {
        final controller = adapter.createEmptyController(readOnly: false);

        adapter.insertAudio(
          controller: controller,
          audioPath: 'audio/test.m4a',
        );

        final json = controller.serialize();
        final newController = adapter.createController(
          json: json,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );

        final hasAudio = newController.serialize().any((op) {
          final insert = op['insert'];
          return insert is Map && insert['audio'] == 'audio/test.m4a';
        });

        expect(hasAudio, isTrue);
      });
    });
  });
}

// Mock class for testing error handling
class _MockRichTextController extends RichTextController {
  @override
  RichTextDocument get document => throw UnimplementedError();

  @override
  String getPlainText() => throw UnimplementedError();

  @override
  bool get readOnly => throw UnimplementedError();

  @override
  void replaceText(int index, int length, Object data, TextSelection? textSelection) {
    throw UnimplementedError();
  }

  @override
  TextSelection get selection => throw UnimplementedError();

  @override
  set selection(TextSelection value) => throw UnimplementedError();

  @override
  List serialize() => throw UnimplementedError();
}
