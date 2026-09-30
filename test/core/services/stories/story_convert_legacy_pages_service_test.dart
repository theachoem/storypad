import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/stories/story_convert_legacy_pages_service.dart';

void main() {
  StoryContentDbModel contentOf(List<StoryPageDbModel> pages) =>
      StoryContentDbModel.create().copyWith(title: pages.first.title, richPages: pages);

  StoryPageDbModel legacy(int id, String text, {String? title}) => StoryPageDbModel.legacy(
    id: id,
    title: title,
    body: [
      {'insert': '$text\n'},
    ],
  );

  final lossy = StoryPageDbModel.legacy(
    id: 9,
    body: [
      {
        'insert': 'big',
        'attributes': {'size': 'large'},
      },
      {'insert': '\n'},
    ],
  );

  group('StoryConvertLegacyPagesService.convertContents', () {
    test('converts the latest and the draft content together', () {
      final latest = contentOf([legacy(1, 'A', title: 'Trip')]);
      final draft = StoryContentDbModel.dublicate(latest);

      final result = StoryConvertLegacyPagesService.convertContents(latest: latest, draft: draft)!;
      expect(result.latest!.hasLegacyPages, isFalse);
      expect(result.draft!.hasLegacyPages, isFalse);
      expect(result.latest!.richPages!.single.markdown, '### Trip\n\nA');
      expect(result.draft!.hasChanges(result.latest!), isFalse);
    });

    test('a content without a draft converts alone', () {
      final result = StoryConvertLegacyPagesService.convertContents(
        latest: contentOf([legacy(1, 'A')]),
        draft: null,
      )!;
      expect(result.latest!.hasLegacyPages, isFalse);
      expect(result.draft, isNull);
    });

    test('nothing to convert: null', () {
      final markdown = contentOf([StoryPageDbModel.create(id: 1, title: 'A')]);
      expect(StoryConvertLegacyPagesService.convertContents(latest: markdown, draft: markdown), isNull);
      expect(StoryConvertLegacyPagesService.convertContents(latest: null, draft: null), isNull);
    });

    test('if either content would lose something, neither is converted', () {
      final latest = contentOf([legacy(1, 'A')]);
      final draft = contentOf([legacy(1, 'A'), lossy]);
      expect(StoryConvertLegacyPagesService.convertContents(latest: latest, draft: draft), isNull);
      expect(StoryConvertLegacyPagesService.convertContents(latest: draft, draft: latest), isNull);
    });
  });

  group('new pages', () {
    test('start empty: no title slot', () {
      final page = StoryPageDbModel.create(id: 1);
      expect(page.markdown, '');
      expect(page.title, isNull);
      expect(page.quillBody, [
        {'insert': '\n'},
      ]);
    });

    test('from a template: its title, then its Markdown body', () {
      final page = StoryPageDbModel.create(id: 1, title: 'Goals', body: '- one\n- two');
      expect(page.markdown, '### Goals\n\n- one\n- two');
      expect(page.title, 'Goals');
    });

    test('a new story with nothing written counts as empty', () {
      final content = StoryContentDbModel.create().addRichPage();
      expect(content.richPages!.single.format, StoryPageFormat.markdownV1);
      expect(content.richPages!.single.markdown, '');
    });
  });
}
