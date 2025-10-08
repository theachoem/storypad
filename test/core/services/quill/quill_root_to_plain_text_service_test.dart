import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';

// Helper function to create a Document from a JSON string (Delta format)
Document _docFromJson(String jsonString) {
  return Document.fromDelta(Delta.fromJson(json.decode(jsonString) as List));
}

void main() {
  group('QuillRootToPlainTextService', () {
    test('should convert simple text correctly', () {
      final doc = _docFromJson('[{"insert":"Hello World\\n"}]');
      final result = QuillRootToPlainTextService.call(doc.root);
      expect(result, 'Hello World\n');
    });

    test('should handle multiple lines', () {
      final doc = _docFromJson('[{"insert":"First line\\nSecond line\\n"}]');
      final result = QuillRootToPlainTextService.call(doc.root);
      expect(result, 'First line\nSecond line\n');
    });

    group('Markdown Formatting', () {
      test('should format bold text', () {
        final doc = _docFromJson('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '**bold text**\n');
      });

      test('should format italic text', () {
        final doc = _docFromJson('[{"insert":"italic text","attributes":{"italic":true}},{"insert":"\\n"}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '*italic text*\n');
      });

      test('should format bold and italic text', () {
        final doc = _docFromJson(
          '[{"insert":"bold and italic","attributes":{"bold":true,"italic":true}},{"insert":"\\n"}]',
        );
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '***bold and italic***\n');
      });

      test('should format a link', () {
        final doc = _docFromJson('[{"insert":"Google","attributes":{"link":"https://google.com"}},{"insert":"\\n"}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '[Google](https://google.com)\n');
      });

      test('should not apply markdown when markdown is false', () {
        final doc = _docFromJson('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]');
        final result = QuillRootToPlainTextService.call(doc.root, markdown: false);
        expect(result, 'bold text\n');
      });
    });

    group('Lists', () {
      test('should format a bulleted list', () {
        final doc = _docFromJson(
          '[{"insert":"Item 1"},{"insert":"\\n","attributes":{"list":"bullet"}},{"insert":"Item 2"},{"insert":"\\n","attributes":{"list":"bullet"}}]',
        );
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '- Item 1\n- Item 2\n');
      });

      test('should format a numbered list with different levels', () {
        final doc = _docFromJson(
          '[{"insert":"First"},{"insert":"\\n","attributes":{"list":"ordered"}},{"insert":"Second"},{"insert":"\\n","attributes":{"list":"ordered"}},{"insert":"Nested A"},{"insert":"\\n","attributes":{"indent":1,"list":"ordered"}},{"insert":"Nested B"},{"insert":"\\n","attributes":{"indent":1,"list":"ordered"}},{"insert":"Deep 1"},{"insert":"\\n","attributes":{"indent":2,"list":"ordered"}},{"insert":"Deep 2"},{"insert":"\\n","attributes":{"indent":2,"list":"ordered"}},{"insert":"Third"},{"insert":"\\n","attributes":{"list":"ordered"}}]',
        );
        const expected =
            '1. First\n'
            '2. Second\n'
            '\ta. Nested A\n'
            '\tb. Nested B\n'
            '\t\ti. Deep 1\n'
            '\t\tii. Deep 2\n'
            '3. Third\n';
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, expected);
      });

      group('markdown = true', () {
        test('should format a checked list item', () {
          final doc = _docFromJson('[{"insert":"Task 1"},{"insert":"\\n","attributes":{"list":"checked"}}]');
          final result = QuillRootToPlainTextService.call(doc.root, markdown: true);
          expect(result, '- [x] Task 1\n');
        });

        test('should format an unchecked list item', () {
          final doc = _docFromJson('[{"insert":"Task 2"},{"insert":"\\n","attributes":{"list":"unchecked"}}]');
          final result = QuillRootToPlainTextService.call(doc.root, markdown: true);
          expect(result, '- [ ] Task 2\n');
        });
      });

      group('markdown = false', () {
        test('should format a checked list item', () {
          final doc = _docFromJson('[{"insert":"Task 1"},{"insert":"\\n","attributes":{"list":"checked"}}]');
          final result = QuillRootToPlainTextService.call(doc.root, markdown: false);
          expect(result, '✅ Task 1\n');
        });

        test('should format an unchecked list item', () {
          final doc = _docFromJson('[{"insert":"Task 2"},{"insert":"\\n","attributes":{"list":"unchecked"}}]');
          final result = QuillRootToPlainTextService.call(doc.root, markdown: false);
          expect(result, '⏹️ Task 2\n');
        });
      });
    });

    group('Blocks', () {
      test('should format a blockquote', () {
        final doc = _docFromJson('[{"insert":"This is a quote."},{"insert":"\\n","attributes":{"blockquote":true}}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '> This is a quote.\n');
      });

      test('should format an indented blockquote', () {
        final doc = _docFromJson(
          '[{"insert":"This is a quote."},{"insert":"\\n","attributes":{"blockquote":true, "indent": 1}}]',
        );
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '> > This is a quote.\n');
      });

      test('should format a code block', () {
        final doc = _docFromJson('[{"insert":"final a = 1;"},{"insert":"\\n","attributes":{"code-block":true}}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '```\nfinal a = 1;\n```\n');
      });
    });

    group('Embeds', () {
      test('should return an empty string for image embeds', () {
        final doc = _docFromJson('[{"insert":{"image":"path/to/image.png"}},{"insert":"\\n"}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, '\n'); // The newline character still exists
      });

      test('should handle other embeds using toPlainText', () {
        // Assuming a hypothetical 'video' embed
        final doc = _docFromJson('[{"insert":{"video":"path/to/video.mp4"}},{"insert":"\\n"}]');
        final result = QuillRootToPlainTextService.call(doc.root);
        // The default toPlainText for unknown embeds is the unicode object replacement char
        expect(result, '\uFFFC\n');
      });
    });

    group('Complex Document', () {
      test('should correctly convert a mixed-content document', () {
        final doc = _docFromJson(r'''
        [
          {"insert":"Title\n"},
          {"insert":"This is some "},
          {"insert":"bold","attributes":{"bold":true}},
          {"insert":" text.\n"},
          {"insert":"An itemized list:"},
          {"insert":"\n","attributes":{"list":"bullet"}},
          {"insert":"First item"},{"insert":"\n","attributes":{"list":"bullet"}},
          {"insert":"A quote:"},
          {"insert":"\n","attributes":{"blockquote":true}},
          {"insert":"And a link to "},
          {"insert":"my site","attributes":{"link":"https://example.com"}},
          {"insert":".\n"}
        ]
        ''');

        const expected =
            'Title\n'
            'This is some **bold** text.\n'
            '- An itemized list:\n'
            '- First item\n'
            '> A quote:\n'
            'And a link to [my site](https://example.com).\n';

        final result = QuillRootToPlainTextService.call(doc.root);
        expect(result, expected);
      });
    });
  });
}
