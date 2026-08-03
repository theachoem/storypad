import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';

// Helper function to create a Document from a JSON string (Delta format)
Document _docFromJson(String jsonString) {
  return Document.fromDelta(Delta.fromJson(json.decode(jsonString) as List));
}

void main() {
  group('QuillDeltaToPlainTextService', () {
    test('should convert simple text correctly', () {
      final doc = _docFromJson('[{"insert":"Hello World\\n"}]');
      final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
      expect(result, 'Hello World\n');
    });

    test('should handle multiple lines', () {
      final doc = _docFromJson('[{"insert":"First line\\nSecond line\\n"}]');
      final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
      expect(result, 'First line\nSecond line\n');
    });

    group('Markdown Formatting', () {
      test('should format bold text', () {
        final doc = _docFromJson('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '**bold text**\n');
      });

      test('should format italic text', () {
        final doc = _docFromJson('[{"insert":"italic text","attributes":{"italic":true}},{"insert":"\\n"}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '*italic text*\n');
      });

      test('should format bold and italic text', () {
        final doc = _docFromJson(
          '[{"insert":"bold and italic","attributes":{"bold":true,"italic":true}},{"insert":"\\n"}]',
        );
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '***bold and italic***\n');
      });

      test('should format a link', () {
        final doc = _docFromJson('[{"insert":"Google","attributes":{"link":"https://google.com"}},{"insert":"\\n"}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '[Google](https://google.com)\n');
      });

      test('should not apply markdown when markdown is false', () {
        final doc = _docFromJson('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson(), markdown: false);
        expect(result, 'bold text\n');
      });
    });

    group('Lists', () {
      test('should format a bulleted list', () {
        final doc = _docFromJson(
          '[{"insert":"Item 1"},{"insert":"\\n","attributes":{"list":"bullet"}},{"insert":"Item 2"},{"insert":"\\n","attributes":{"list":"bullet"}}]',
        );
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
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
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, expected);
      });

      test('should handle ordered lists exceeding 26 items with fallback to numbers', () {
        // Create a list with 28 items at indent level 1 (should use a-z, then fallback to 27. 28.)
        final items = <Map<String, dynamic>>[];
        for (int i = 1; i <= 28; i++) {
          items.add({"insert": "Item $i"});
          items.add({
            "insert": "\n",
            "attributes": {"indent": 1, "list": "ordered"},
          });
        }

        final doc = _docFromJson(json.encode(items));
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());

        // First 26 should be a-z, then 27 and 28 should be numbers
        expect(result.contains('\ta. Item 1\n'), true);
        expect(result.contains('\tz. Item 26\n'), true);
        expect(result.contains('\t27. Item 27\n'), true);
        expect(result.contains('\t28. Item 28\n'), true);
      });

      group('markdown = true', () {
        test('should format a checked list item', () {
          final doc = _docFromJson('[{"insert":"Task 1"},{"insert":"\\n","attributes":{"list":"checked"}}]');
          final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson(), markdown: true);
          expect(result, '- [x] Task 1\n');
        });

        test('should format an unchecked list item', () {
          final doc = _docFromJson('[{"insert":"Task 2"},{"insert":"\\n","attributes":{"list":"unchecked"}}]');
          final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson(), markdown: true);
          expect(result, '- [ ] Task 2\n');
        });
      });

      group('markdown = false', () {
        test('should format a checked list item', () {
          final doc = _docFromJson('[{"insert":"Task 1"},{"insert":"\\n","attributes":{"list":"checked"}}]');
          final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson(), markdown: false);
          expect(result, '✅ Task 1\n');
        });

        test('should format an unchecked list item', () {
          final doc = _docFromJson('[{"insert":"Task 2"},{"insert":"\\n","attributes":{"list":"unchecked"}}]');
          final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson(), markdown: false);
          expect(result, '⏹️ Task 2\n');
        });
      });
    });

    group('Blocks', () {
      test('should format a blockquote', () {
        final doc = _docFromJson('[{"insert":"This is a quote."},{"insert":"\\n","attributes":{"blockquote":true}}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '> This is a quote.\n');
      });

      test('should format an indented blockquote', () {
        final doc = _docFromJson(
          '[{"insert":"This is a quote."},{"insert":"\\n","attributes":{"blockquote":true, "indent": 1}}]',
        );
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '> > This is a quote.\n');
      });

      test('should format a code block', () {
        final doc = _docFromJson('[{"insert":"final a = 1;"},{"insert":"\\n","attributes":{"code-block":true}}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '```\nfinal a = 1;\n```\n');
      });
    });

    group('Embeds', () {
      test('should return an empty string for image embeds', () {
        final doc = _docFromJson('[{"insert":{"media":"path/to/image.png"}},{"insert":"\\n"}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, '\n'); // The newline character still exists
      });

      test('should handle other embeds using toPlainText', () {
        // Assuming a hypothetical 'video' embed
        final doc = _docFromJson('[{"insert":{"video":"path/to/video.mp4"}},{"insert":"\\n"}]');
        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        // The default toPlainText for unknown embeds is the unicode object replacement char
        expect(result, '\uFFFC\n');
      });

      test('the legacy `image` embed key is treated the same as `media`', () {
        const delta = '[{"insert":{"image":"images/1.jpg"}},{"insert":"\\n"}]';
        final doc = _docFromJson(delta);
        final result = QuillDeltaToPlainTextService.call(
          doc.root.toDelta().toJson(),
          includeMarkdownEmbeds: true,
        );
        expect(result, '![image](images/1.jpg)\n');
      });

      test('a legacy `image` embed holding a video path still emits a link', () {
        const delta = '[{"insert":{"image":"videos/1.mp4"}},{"insert":"\\n"}]';
        final doc = _docFromJson(delta);
        final result = QuillDeltaToPlainTextService.call(
          doc.root.toDelta().toJson(),
          includeMarkdownEmbeds: true,
        );
        expect(result, '[video](videos/1.mp4)\n');
      });

      group('Album embed (pipe-delimited format)', () {
        test('single image embed is unchanged with includeMarkdownEmbeds=true', () {
          const delta = '[{"insert":{"media":"images/1.jpg"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
          );
          expect(result, '![image](images/1.jpg)\n');
        });

        test('album embed emits one markdown entry per image', () {
          const delta = '[{"insert":{"media":"images/1.jpg|images/2.jpg|images/3.jpg"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
          );
          expect(result, '![image](images/1.jpg)![image](images/2.jpg)![image](images/3.jpg)\n');
        });

        test('album embed with embedRelativePath prefix applies to each image', () {
          const delta = '[{"insert":{"media":"images/1.jpg|images/2.jpg"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
            embedRelativePath: '../',
          );
          expect(result, '![image](../images/1.jpg)![image](../images/2.jpg)\n');
        });

        test('album embed with external URLs is not prefixed', () {
          const delta = '[{"insert":{"media":"https://a.com/1.jpg|https://b.com/2.jpg"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
            embedRelativePath: '../',
          );
          expect(result, '![image](https://a.com/1.jpg)![image](https://b.com/2.jpg)\n');
        });

        test('album embed without includeMarkdownEmbeds produces only newline', () {
          const delta = '[{"insert":{"media":"images/1.jpg|images/2.jpg"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: false,
          );
          expect(result, '\n');
        });

        test('trailing pipe in album embed is ignored', () {
          const delta = '[{"insert":{"media":"images/1.jpg|"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
          );
          expect(result, '![image](images/1.jpg)\n');
        });

        // Photos and video share the `media` embed key by design (see
        // docs/app/features/media.md), so a `videos/` path arriving through
        // the `media` embedType must emit a link, not an image tag pointing
        // at an .mp4.
        test('a video path under the image embed emits a link, not an image tag', () {
          const delta = '[{"insert":{"media":"videos/1.mp4"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
          );
          expect(result, '[video](videos/1.mp4)\n');
        });

        test('a mixed photo+video album emits an image tag and a link respectively', () {
          const delta = '[{"insert":{"media":"images/1.jpg|videos/2.mp4"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
          );
          expect(result, '![image](images/1.jpg)[video](videos/2.mp4)\n');
        });

        test('video link respects embedRelativePath the same way image tags do', () {
          const delta = '[{"insert":{"media":"videos/1.mp4"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: true,
            embedRelativePath: '../',
          );
          expect(result, '[video](../videos/1.mp4)\n');
        });

        test('video path without includeMarkdownEmbeds produces only newline', () {
          // Regression guard: the link form must stay inside the
          // includeMarkdownEmbeds branch. If it leaked into the
          // includeMarkdownEmbeds=false path (used for word counting), the
          // link's visible text would survive MarkdownContentFilterService --
          // unlike an image tag, which it strips entirely -- silently
          // inflating wordCount for any story with an embedded video.
          const delta = '[{"insert":{"media":"videos/1.mp4"}},{"insert":"\\n"}]';
          final doc = _docFromJson(delta);
          final result = QuillDeltaToPlainTextService.call(
            doc.root.toDelta().toJson(),
            includeMarkdownEmbeds: false,
          );
          expect(result, '\n');
        });
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

        final result = QuillDeltaToPlainTextService.call(doc.root.toDelta().toJson());
        expect(result, expected);
      });
    });
  });
}
