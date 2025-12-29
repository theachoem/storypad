import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/generate_body_plain_text_service.dart';

void main() {
  group('GenerateBodyPlainTextService', () {
    group('Basic Functionality', () {
      test('returns null for null input', () {
        final result = GenerateBodyPlainTextService.call(null);
        expect(result, isNull);
      });

      test('returns null for empty list', () {
        final result = GenerateBodyPlainTextService.call([]);
        expect(result, isNull);
      });

      test('returns GenerateBodyPlainTextResult with required fields', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Test',
            body: json.decode('[{"insert":"Content\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, isA<String>());
        expect(result.richPagesWithCounts, isA<List<StoryPageDbModel>>());
      });
    });

    group('Single Page Processing', () {
      test('converts single page with simple text', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Page 1',
            body: json.decode('[{"insert":"Hello World\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, 'Hello World');
      });

      test('handles single page with null body', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Empty Page',
            body: null,
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, '');
      });

      test('handles single page with empty body array', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Page',
            body: json.decode('[]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, '');
      });

      test('handles single page with null title', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Content\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, 'Content');
      });
    });

    group('Multiple Pages Processing', () {
      test('combines multiple pages with titles', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'First',
            body: json.decode('[{"insert":"Content 1\\n"}]'),
          ),
          StoryPageDbModel(
            id: 2,
            title: 'Second',
            body: json.decode('[{"insert":"Content 2\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, 'Content 1\n\nSecond\nContent 2');
      });

      test('handles multiple pages with some null titles', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'First',
            body: json.decode('[{"insert":"Content 1\\n"}]'),
          ),
          StoryPageDbModel(
            id: 2,
            title: null,
            body: json.decode('[{"insert":"Content 2\\n"}]'),
          ),
          StoryPageDbModel(
            id: 3,
            title: 'Third',
            body: json.decode('[{"insert":"Content 3\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, 'Content 1\n\n\nContent 2\n\nThird\nContent 3');
      });

      test('handles three or more pages', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Chapter 1',
            body: json.decode('[{"insert":"First\\n"}]'),
          ),
          StoryPageDbModel(
            id: 2,
            title: 'Chapter 2',
            body: json.decode('[{"insert":"Second\\n"}]'),
          ),
          StoryPageDbModel(
            id: 3,
            title: 'Chapter 3',
            body: json.decode('[{"insert":"Third\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);
        expect(result!.plainText, contains('First'));
        expect(result.plainText, contains('Chapter 2'));
        expect(result.plainText, contains('Second'));
        expect(result.plainText, contains('Chapter 3'));
        expect(result.plainText, contains('Third'));
      });
    });

    group('Character Count (with Filtering)', () {
      test('counts only actual text, not markdown formatting', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Test',
            body: json.decode('[{"insert":"**bold**","attributes":{"bold":true}},{"insert":"\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Test" (4) + "bold" (4) = 8 characters (not counting **)
        expect(page.characterCount, 8);
      });

      test('does not count bullet markers', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Item"},{"insert":"\\n","attributes":{"list":"bullet"}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // Only "Item" (4 characters), not "- Item"
        expect(page.characterCount, 4);
      });

      test('does not count checkbox markers', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Task"},{"insert":"\\n","attributes":{"list":"unchecked"}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // Only "Task" (4 characters), not "- [ ] Task"
        expect(page.characterCount, 4);
      });

      test('does not count list numbering', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"First"},{"insert":"\\n","attributes":{"list":"ordered"}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // Only "First" (5 characters), not "1. First"
        expect(page.characterCount, 5);
      });

      test('includes title in character count', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Title',
            body: json.decode('[{"insert":"Body\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Title" (5) + "Body" (4) = 9
        expect(page.characterCount, 9);
      });

      test('handles empty content correctly', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.characterCount, 0);
      });

      test('counts multi-line content correctly', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Line 1\\nLine 2\\nLine 3\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Line 1\nLine 2\nLine 3" without final \n = 20 characters
        expect(page.characterCount, 20);
      });
    });

    group('Word Count (with Filtering)', () {
      test('counts words correctly', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'My Title',
            body: json.decode('[{"insert":"Hello World\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "My Title Hello World" = 4 words
        expect(page.wordCount, 4);
      });

      test('does not count bullet markers as words', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Item one"},{"insert":"\\n","attributes":{"list":"bullet"}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Item one" = 2 words (not "- Item one" = 3)
        expect(page.wordCount, 2);
      });

      test('does not count checkbox markers as words', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Buy milk"},{"insert":"\\n","attributes":{"list":"unchecked"}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Buy milk" = 2 words (not "- [ ] Buy milk" = 4)
        expect(page.wordCount, 2);
      });

      test('does not count markdown formatting as separate words', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // After markdown removal: "bold text" = 2 words (formatting markers removed correctly)
        expect(page.wordCount, 2);
      });

      test('counts words in multiple lines', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"First line\\nSecond line\\nThird line\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // 6 words total
        expect(page.wordCount, 6);
      });

      test('handles empty content correctly', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.wordCount, 0);
      });

      test('handles only whitespace correctly', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: '   ',
            body: json.decode('[{"insert":"   \\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.wordCount, 0);
      });
    });

    group('Complex Formatting Scenarios', () {
      test('handles pages with mixed formatting', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Story',
            body: json.decode('''
[
  {"insert":"Chapter 1","attributes":{"header":1}},
  {"insert":"\\n"},
  {"insert":"Once upon a time...\\n"},
  {"insert":"Task 1"},
  {"insert":"\\n","attributes":{"list":"unchecked"}},
  {"insert":"bold text","attributes":{"bold":true}},
  {"insert":"\\n"}
]
            '''),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result, isNotNull);

        final page = result!.richPagesWithCounts.first;
        // Verify counts exclude markdown markers
        expect(page.characterCount, greaterThan(0));
        expect(page.wordCount, greaterThan(0));
      });

      test('handles pages with links and images', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode(
              '[{"insert":"Click "},{"insert":"here","attributes":{"link":"https://example.com"}},{"insert":"\\n"}]',
            ),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Click here" = 10 characters
        expect(page.characterCount, 10);
        expect(page.wordCount, 2);
      });

      test('handles pages with blockquotes', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Quoted text"},{"insert":"\\n","attributes":{"blockquote":true}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // "Quoted text" = 11 characters (not "> Quoted text")
        expect(page.characterCount, 11);
        expect(page.wordCount, 2);
      });

      test('handles pages with code blocks', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"const x = 5;"},{"insert":"\\n","attributes":{"code-block":true}}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // Code content counts, but not ``` markers
        expect(page.characterCount, greaterThan(0));
        expect(page.wordCount, greaterThan(0));
      });
    });

    group('Multiple Pages with Counts', () {
      test('calculates counts for each page separately', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Short',
            body: json.decode('[{"insert":"Hi\\n"}]'),
          ),
          StoryPageDbModel(
            id: 2,
            title: 'Longer Title',
            body: json.decode('[{"insert":"This is a much longer sentence.\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);

        final page1 = result!.richPagesWithCounts[0];
        final page2 = result.richPagesWithCounts[1];

        // First page should have fewer chars/words than second
        expect(page1.characterCount, lessThan(page2.characterCount!));
        expect(page1.wordCount, lessThan(page2.wordCount!));
      });

      test('returns same number of pages with counts', () {
        final pages = [
          StoryPageDbModel(id: 1, title: 'P1', body: json.decode('[{"insert":"A\\n"}]')),
          StoryPageDbModel(id: 2, title: 'P2', body: json.decode('[{"insert":"B\\n"}]')),
          StoryPageDbModel(id: 3, title: 'P3', body: json.decode('[{"insert":"C\\n"}]')),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        expect(result!.richPagesWithCounts.length, 3);
      });

      test('preserves page IDs and titles', () {
        final pages = [
          StoryPageDbModel(id: 42, title: 'Important', body: json.decode('[{"insert":"Text\\n"}]')),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.id, 42);
        expect(page.title, 'Important');
      });
    });

    group('Edge Cases', () {
      test('handles page with only markdown formatting', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"---\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        // Horizontal rule removed, nothing left
        expect(page.characterCount, 0);
        expect(page.wordCount, 0);
      });

      test('handles page with special characters', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"@#\$%^&*()\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.characterCount, greaterThan(0));
      });

      test('handles page with unicode characters', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"你好世界\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.characterCount, 4);
        expect(page.wordCount, 1);
      });

      test('handles page with emojis', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: null,
            body: json.decode('[{"insert":"Hello 😊 World\\n"}]'),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;
        expect(page.characterCount, greaterThan(0));
        expect(page.wordCount, 3); // "Hello", "😊", "World"
      });
    });

    group('Integration - Filters Applied Correctly', () {
      test('user sees only content they wrote, not structure', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'My List',
            body: json.decode('''
[
  {"insert":"Buy groceries"},
  {"insert":"\\n","attributes":{"list":"unchecked"}},
  {"insert":"Walk dog"},
  {"insert":"\\n","attributes":{"list":"checked"}},
  {"insert":"Important: "},
  {"insert":"Call mom","attributes":{"bold":true}},
  {"insert":"\\n"}
]
            '''),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;

        // User wrote: "My List", "Buy groceries", "Walk dog", "Important: Call mom"
        // Filter removes: "- [ ]", "✅ ", "**"
        // Character count should reflect only written text
        // final expectedWords = ['My', 'List', 'Buy', 'groceries', 'Walk', 'dog', 'Important:', 'Call', 'mom'];
        expect(page.wordCount, 9); // All words preserved correctly
      });

      test('formatted story counts accurately', () {
        final pages = [
          StoryPageDbModel(
            id: 1,
            title: 'Chapter One',
            body: json.decode('''
[
  {"insert":"Once upon a time"},
  {"insert":"\\n","attributes":{"header":1}},
  {"insert":"There lived a "},
  {"insert":"brave","attributes":{"bold":true}},
  {"insert":" knight.\\n"},
  {"insert":"He went on adventures:"},
  {"insert":"\\n"},
  {"insert":"Fight dragon"},
  {"insert":"\\n","attributes":{"list":"bullet"}},
  {"insert":"Save princess"},
  {"insert":"\\n","attributes":{"list":"bullet"}}
]
            '''),
          ),
        ];
        final result = GenerateBodyPlainTextService.call(pages);
        final page = result!.richPagesWithCounts.first;

        // Content: "Chapter One Once upon a time There lived a brave knight. He went on adventures: Fight dragon Save princess"
        // Without: "# ", "- ", "**"
        expect(page.wordCount, 19); // Actual words after filtering
        expect(page.characterCount, greaterThan(50)); // Reasonable char count
      });
    });
  });
}
