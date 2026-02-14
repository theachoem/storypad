import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

void main() {
  group('QuillRichTextDocument', () {
    group('fromJson()', () {
      test('creates document from valid JSON', () {
        final json = [
          {'insert': 'Hello World'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        expect(document, isA<RichTextDocument>());
        expect(document.toPlainText(), equals('Hello World\n'));
      });

      test('creates document with formatted text', () {
        final json = [
          {
            'insert': 'Bold text',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        expect(document.toPlainText(), equals('Bold text\n'));
        expect(document.toJson(), equals(json));
      });

      test('creates document with embeds', () {
        final json = [
          {'insert': 'Before embed'},
          {
            'insert': {'image': 'images/test.jpg'},
          },
          {'insert': 'After embed'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        expect(document.toPlainText(), contains('Before embed'));
        expect(document.toPlainText(), contains('After embed'));
      });

      test('handles empty JSON array through adapter', () {
        // Note: QuillRichTextDocument.fromJson doesn't handle empty arrays,
        // but the adapter (createDocument) does.
        final document = editorAdapter.createDocument(json: []);

        // Empty document should have a newline
        expect(document.toPlainText(), equals('\n'));
        expect(document.length, equals(1));
      });

      test('handles complex nested structures', () {
        final json = [
          {
            'insert': 'Heading',
            'attributes': {'header': 1},
          },
          {'insert': '\n'},
          {
            'insert': 'List item 1',
            'attributes': {'list': 'bullet'},
          },
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        expect(document.toJson(), equals(json));
      });
    });

    group('empty()', () {
      test('creates empty document', () {
        final document = QuillRichTextDocument.empty();

        expect(document, isA<RichTextDocument>());
        expect(document.length, equals(1)); // Quill documents always have at least \n
        expect(document.toPlainText(), equals('\n'));
      });

      test('empty document can be serialized', () {
        final document = QuillRichTextDocument.empty();
        final json = document.toJson();

        expect(json, isA<List>());
        expect(json.length, greaterThan(0));
      });
    });

    group('length', () {
      test('returns correct length for simple text', () {
        final json = [
          {'insert': 'Hello'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        // "Hello\n" = 6 characters
        expect(document.length, equals(6));
      });

      test('returns correct length for empty document', () {
        final document = QuillRichTextDocument.empty();

        // Empty document has one newline
        expect(document.length, equals(1));
      });

      test('counts embeds as single character', () {
        final json = [
          {'insert': 'Text'},
          {
            'insert': {'image': 'images/test.jpg'},
          },
          {'insert': 'More'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        // "Text" (4) + embed (1) + "More" (4) + "\n" (1) = 10
        expect(document.length, equals(10));
      });
    });

    group('toPlainText()', () {
      test('returns plain text without formatting', () {
        final json = [
          {
            'insert': 'Bold',
            'attributes': {'bold': true},
          },
          {'insert': ' '},
          {
            'insert': 'Italic',
            'attributes': {'italic': true},
          },
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        expect(document.toPlainText(), equals('Bold Italic\n'));
      });

      test('handles multiline text', () {
        final json = [
          {'insert': 'Line 1'},
          {'insert': '\n'},
          {'insert': 'Line 2'},
          {'insert': '\n'},
          {'insert': 'Line 3'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);

        expect(document.toPlainText(), equals('Line 1\nLine 2\nLine 3\n'));
      });

      test('includes embed markers', () {
        final json = [
          {'insert': 'Text before'},
          {
            'insert': {'image': 'images/photo.jpg'},
          },
          {'insert': 'Text after'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);
        final plainText = document.toPlainText();

        expect(plainText, contains('Text before'));
        expect(plainText, contains('Text after'));
        // Embeds are represented as special characters in plain text
        expect(plainText.length, greaterThan('Text beforeText after\n'.length));
      });

      test('returns newline for empty document', () {
        final document = QuillRichTextDocument.empty();

        expect(document.toPlainText(), equals('\n'));
      });
    });

    group('toJson()', () {
      test('returns optimized JSON structure', () {
        final originalJson = [
          {'insert': 'Test content'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(originalJson);
        final serializedJson = document.toJson();

        // Quill optimizes by merging consecutive text operations
        expect(
          serializedJson,
          equals([
            {'insert': 'Test content\n'},
          ]),
        );
      });

      test('preserves all formatting attributes', () {
        final originalJson = [
          {
            'insert': 'Formatted',
            'attributes': {
              'bold': true,
              'italic': true,
              'underline': true,
              'color': '#FF0000',
            },
          },
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(originalJson);
        final serializedJson = document.toJson();

        expect(serializedJson, equals(originalJson));
      });

      test('preserves embed data correctly', () {
        final originalJson = [
          {
            'insert': {'image': 'images/photo.jpg'},
          },
          {
            'insert': {'audio': 'audio/recording.m4a'},
          },
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(originalJson);
        final serializedJson = document.toJson();

        expect(serializedJson, equals(originalJson));
      });

      test('returns valid JSON for empty document', () {
        final document = QuillRichTextDocument.empty();
        final json = document.toJson();

        expect(json, isA<List<dynamic>>());
        expect(json, isNotEmpty);
      });

      test('handles block-level formatting', () {
        final originalJson = [
          {
            'insert': 'Heading',
            'attributes': {'header': 1},
          },
          {'insert': '\n'},
          {
            'insert': 'List item',
            'attributes': {'list': 'bullet'},
          },
          {'insert': '\n'},
          {
            'insert': 'Code block',
            'attributes': {'code-block': true},
          },
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(originalJson);
        final serializedJson = document.toJson();

        expect(serializedJson, equals(originalJson));
      });
    });

    group('quillDocument', () {
      test('provides access to underlying Quill document', () {
        final json = [
          {'insert': 'Test'},
          {'insert': '\n'},
        ];

        final document = QuillRichTextDocument.fromJson(json);
        final quillDoc = document.quillDocument;

        expect(quillDoc, isNotNull);
        expect(quillDoc.toPlainText(), equals('Test\n'));
      });
    });

    group('round-trip serialization', () {
      test('maintains data integrity through multiple serializations', () {
        final originalJson = [
          {
            'insert': 'Complex',
            'attributes': {'bold': true, 'italic': true},
          },
          {'insert': ' content with '},
          {
            'insert': {'image': 'images/test.jpg'},
          },
          {'insert': ' and more text'},
          {'insert': '\n'},
        ];

        // First round-trip
        final doc1 = QuillRichTextDocument.fromJson(originalJson);
        final json1 = doc1.toJson();

        // Second round-trip
        final doc2 = QuillRichTextDocument.fromJson(json1);
        final json2 = doc2.toJson();

        // Third round-trip
        final doc3 = QuillRichTextDocument.fromJson(json2);
        final json3 = doc3.toJson();

        // All serialized versions should be identical (though may differ from original due to optimization)
        expect(json1, equals(json2));
        expect(json2, equals(json3));

        // Plain text should be preserved
        expect(doc1.toPlainText(), equals(doc2.toPlainText()));
        expect(doc2.toPlainText(), equals(doc3.toPlainText()));
      });

      test('maintains plain text through serialization', () {
        final originalJson = [
          {'insert': 'Hello World'},
          {'insert': '\n'},
        ];

        final doc1 = QuillRichTextDocument.fromJson(originalJson);
        final plainText1 = doc1.toPlainText();

        final doc2 = QuillRichTextDocument.fromJson(doc1.toJson());
        final plainText2 = doc2.toPlainText();

        expect(plainText1, equals(plainText2));
      });
    });
  });
}
