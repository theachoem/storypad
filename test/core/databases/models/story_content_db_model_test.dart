import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';

void main() {
  final pages = [
    StoryPageDbModel.create(id: 1, title: 'Goals', body: 'Run more'),
    StoryPageDbModel.create(id: 2, title: 'Notes', body: 'Sleep early'),
  ];

  test('withPages works out the title, plain text and counts from the pages (e.g. a content from a template)', () {
    final content = StoryContentDbModel.create().withPages(pages);
    expect(content.title, 'Goals');
    expect(content.plainText, contains('Run more'));
    expect(content.plainText, contains('Sleep early'));
    expect(content.wordCount, greaterThan(0));
  });

  test('editing a later page keeps the title in step with the first page, even if it was missing', () {
    final content = StoryContentDbModel.create().copyWith(richPages: pages);
    expect(content.title, isNull);

    final edited = content.replacePage(pages[1].withMarkdown('### Notes\n\nSleep at ten'));
    expect(edited.title, 'Goals');
    expect(edited.plainText, contains('Sleep at ten'));
  });

  test('removing or reordering pages takes the new first page title', () {
    final content = StoryContentDbModel.create().withPages(pages);
    expect(content.removeRichPage(1).title, 'Notes');
    expect(content.reorder(oldIndex: 1, newIndex: 0).title, 'Notes');
  });
}
