import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/generate_body_plain_text_service.dart';

void main() {
  group('GenerateBodyPlainTextService', () {
    test('should return null for null input', () {
      final result = GenerateBodyPlainTextService.call(null);
      expect(result, isNull);
    });

    test('should return null for empty list', () {
      final result = GenerateBodyPlainTextService.call([]);
      expect(result, isNull);
    });

    test('should convert single page with simple text', () {
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

    test('should convert single page with empty body', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page 1',
          body: null,
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, '');
    });

    test('should convert single page with formatted text', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page 1',
          body: json.decode('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, '**bold text**');
    });

    test('should convert multiple pages with titles and bodies', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'First Page',
          body: json.decode('[{"insert":"First page content\\n"}]'),
        ),
        StoryPageDbModel(
          id: 2,
          title: 'Second Page',
          body: json.decode('[{"insert":"Second page content\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, 'First page content\n\nSecond Page\nSecond page content');
    });

    test('should handle multiple pages where subsequent pages have null titles', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'First Page',
          body: json.decode('[{"insert":"First page content\\n"}]'),
        ),
        StoryPageDbModel(
          id: 2,
          title: null,
          body: json.decode('[{"insert":"Second page content\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      // Empty string is added for null title
      expect(result, isNotNull);
      expect(result!.plainText, 'First page content\n\n\nSecond page content');
    });

    test('should convert multiple pages with complex formatting', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Introduction',
          body: json.decode(
            '[{"insert":"Welcome to "},{"insert":"my story","attributes":{"bold":true}},{"insert":"!\\n"}]',
          ),
        ),
        StoryPageDbModel(
          id: 2,
          title: 'Chapter 1',
          body: json.decode('[{"insert":"Once upon a time...\\n"}]'),
        ),
        StoryPageDbModel(
          id: 3,
          title: 'Chapter 2',
          body: json.decode('[{"insert":"The end.\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, 'Welcome to **my story**!\n\nChapter 1\nOnce upon a time...\n\nChapter 2\nThe end.');
    });

    test('should handle pages with lists', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Todo List',
          body: json.decode(
            '[{"insert":"Task 1"},{"insert":"\\n","attributes":{"list":"bullet"}},{"insert":"Task 2"},{"insert":"\\n","attributes":{"list":"bullet"}}]',
          ),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, '- Task 1\n- Task 2');
    });

    test('should handle pages with blockquotes', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Quotes',
          body: json.decode('[{"insert":"Be yourself."},{"insert":"\\n","attributes":{"blockquote":true}}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, '> Be yourself.');
    });

    test('should handle pages with links', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Links',
          body: json.decode(
            '[{"insert":"Visit "},{"insert":"Google","attributes":{"link":"https://google.com"}},{"insert":"\\n"}]',
          ),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, 'Visit [Google](https://google.com)');
    });

    test('should trim trailing whitespace from result', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page',
          body: json.decode('[{"insert":"Content\\n\\n\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, 'Content');
    });

    test('should handle complex multi-page document', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Title Page',
          body: json.decode('[{"insert":"My Story\\n"},{"insert":"by Author\\n"}]'),
        ),
        StoryPageDbModel(
          id: 2,
          title: 'Chapter 1: The Beginning',
          body: json.decode(
            '[{"insert":"It was a "},{"insert":"dark","attributes":{"italic":true}},{"insert":" and stormy night.\\n"}]',
          ),
        ),
        StoryPageDbModel(
          id: 3,
          title: 'Chapter 2: The Middle',
          body: json.decode(
            '[{"insert":"Things happened."},{"insert":"\\n","attributes":{"list":"bullet"}},{"insert":"More things."},{"insert":"\\n","attributes":{"list":"bullet"}}]',
          ),
        ),
        StoryPageDbModel(
          id: 4,
          title: 'Chapter 3: The End',
          body: json.decode('[{"insert":"The end."},{"insert":"\\n","attributes":{"blockquote":true}}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      const expected =
          'My Story\nby Author\n'
          '\n'
          'Chapter 1: The Beginning\n'
          'It was a *dark* and stormy night.\n'
          '\n'
          'Chapter 2: The Middle\n'
          '- Things happened.\n'
          '- More things.\n'
          '\n'
          'Chapter 3: The End\n'
          '> The end.';
      expect(result!.plainText, expected);
    });

    test('should handle pages with empty body arrays', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Empty Page',
          body: [],
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, '');
    });

    test('should apply markdown formatting by default', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Formatted',
          body: json.decode('[{"insert":"bold","attributes":{"bold":true}},{"insert":"\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      expect(result!.plainText, '**bold**');
    });

    test('should calculate word count correctly with title', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Hello World',
          body: json.decode('[{"insert":"This is body\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      // Word count: "Hello" + "World" + "This" + "is" + "body" = 5 words
      expect(result!.richPagesWithCounts[0].wordCount, 5);
    });

    test('should calculate character count correctly including title', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'My Title',
          body: json.decode('[{"insert":"Hello World\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
      // characterCount = title length (8) + body length (12) = 20
      expect(result!.richPagesWithCounts[0].characterCount, 20);
    });

    test('should calculate total character count correctly', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page',
          body: json.decode('[{"insert":"Body\\n"}]'),
        ),
        StoryPageDbModel(
          id: 2,
          title: 'Two',
          body: json.decode('[{"insert":"Data\\n"}]'),
        ),
      ];
      final result = GenerateBodyPlainTextService.call(pages);
      expect(result, isNotNull);
    });
  });
}
