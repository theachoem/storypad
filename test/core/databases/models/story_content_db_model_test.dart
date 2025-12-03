import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';

void main() {
  group('StoryContentDbModel.generateBodyPlainText', () {
    test('should return null when richPages is null', () {
      final result = StoryContentDbModel.generateBodyPlainText(null);
      expect(result, isNull);
    });

    test('should return null when richPages is empty', () {
      final result = StoryContentDbModel.generateBodyPlainText([]);
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, 'Hello World');
    });

    test('should convert single page with empty body', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page 1',
          body: null,
        ),
      ];
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, '');
    });

    test('should convert single page with formatted text', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page 1',
          body: json.decode('[{"insert":"bold text","attributes":{"bold":true}},{"insert":"\\n"}]'),
        ),
      ];
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, '**bold text**');
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, 'First page content\n\nSecond Page\nSecond page content');
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      // Empty string is added for null title
      expect(result, 'First page content\n\n\nSecond page content');
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, 'Welcome to **my story**!\n\nChapter 1\nOnce upon a time...\n\nChapter 2\nThe end.');
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, '- Task 1\n- Task 2');
    });

    test('should handle pages with blockquotes', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Quotes',
          body: json.decode('[{"insert":"Be yourself."},{"insert":"\\n","attributes":{"blockquote":true}}]'),
        ),
      ];
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, '> Be yourself.');
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, 'Visit [Google](https://google.com)');
    });

    test('should trim trailing whitespace from result', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Page',
          body: json.decode('[{"insert":"Content\\n\\n\\n"}]'),
        ),
      ];
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, 'Content');
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
      final result = StoryContentDbModel.generateBodyPlainText(pages);
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
      expect(result, expected);
    });

    test('should handle pages with empty body arrays', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Empty Page',
          body: [],
        ),
      ];
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, '');
    });

    test('should apply markdown formatting by default', () {
      final pages = [
        StoryPageDbModel(
          id: 1,
          title: 'Formatted',
          body: json.decode('[{"insert":"bold","attributes":{"bold":true}},{"insert":"\\n"}]'),
        ),
      ];
      final result = StoryContentDbModel.generateBodyPlainText(pages);
      expect(result, '**bold**');
    });
  });
}
