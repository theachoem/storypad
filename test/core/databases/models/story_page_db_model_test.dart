import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/generate_body_plain_text_service.dart';

void main() {
  // A legacy page as older versions stored it: a separate title and a Quill body.
  final legacyJson = <String, dynamic>{
    'id': 1,
    'title': 'Trip',
    'word_count': 5,
    'character_count': 20,
    'body': [
      {'insert': 'Went '},
      {
        'insert': 'swimming',
        'attributes': {'bold': true},
      },
      {'insert': '\nFirst'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {
        'insert': {'media': 'images/1.jpg|images/2.jpg'},
        'attributes': {'custom-embed-size': 'max'},
      },
      {'insert': '\n'},
    ],
  };

  group('legacy pages', () {
    test('read and write back exactly as older versions stored them', () {
      final page = StoryPageDbModel.fromJson(legacyJson);
      expect(page.isLegacy, isTrue);
      expect(page.format, isNull);
      expect(page.toJson(), legacyJson);
    });

    test('read as Markdown with the title as a leading heading', () {
      final page = StoryPageDbModel.fromJson(legacyJson);
      expect(page.title, 'Trip');
      expect(page.markdown, startsWith('### Trip\n\nWent **swimming**'));
      expect(page.quillBody, legacyJson['body']);
    });

    test('convert losslessly to a Markdown page with the same id and counts', () {
      final page = StoryPageDbModel.fromJson(legacyJson);
      expect(page.checkConversion().isLossless, isTrue);

      final converted = page.toMarkdownPage();
      expect(converted.isLegacy, isFalse);
      expect(converted.format, StoryPageFormat.markdownV1);
      expect(converted.id, 1);
      expect(converted.wordCount, 5);
      expect(converted.toJson(), {
        'id': 1,
        'format': 'markdown_v1',
        'word_count': 5,
        'character_count': 20,
        'markdown': page.markdown,
      });
    });

    test('a page with formatting the conversion drops fails the check', () {
      final page = StoryPageDbModel.legacy(
        id: 1,
        title: 'Trip',
        body: [
          {
            'insert': 'big',
            'attributes': {'size': 'large'},
          },
          {'insert': '\n'},
        ],
      );
      expect(page.checkConversion().isLossless, isFalse);
    });

    test('an untitled page with no body reads as empty', () {
      final page = StoryPageDbModel.legacy(id: 1, title: null, body: null);
      expect(page.markdown, '');
      expect(page.title, isNull);
      expect(page.quillBody, isEmpty);
    });
  });

  group('Markdown pages', () {
    test('round-trip through JSON', () {
      final page = StoryPageDbModel.markdown(id: 2, markdown: '### Trip\n\nbody', wordCount: 2, characterCount: 8);
      final json = page.toJson();
      expect(json, {
        'id': 2,
        'format': 'markdown_v1',
        'word_count': 2,
        'character_count': 8,
        'markdown': '### Trip\n\nbody',
      });
      final read = StoryPageDbModel.fromJson(json);
      expect(read.format, StoryPageFormat.markdownV1);
      expect(read.markdown, '### Trip\n\nbody');
    });

    test('the title is the leading heading; the Quill body leaves it out', () {
      final page = StoryPageDbModel.markdown(id: 2, markdown: '### Trip\n\nWent **swimming**');
      expect(page.title, 'Trip');
      expect(page.quillBody, [
        {'insert': 'Went '},
        {
          'insert': 'swimming',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
    });

    test('no leading heading, no title', () {
      final page = StoryPageDbModel.markdown(id: 2, markdown: 'Went\n\n### Later');
      expect(page.title, isNull);
    });

    test('its Quill body is equivalent to the legacy body it was converted from', () {
      final legacy = StoryPageDbModel.fromJson(legacyJson);
      final converted = StoryPageDbModel.fromJson(legacy.toMarkdownPage().toJson());
      expect(converted.title, legacy.title);
      expect(converted.quillBody, legacyJson['body']);
    });
  });

  group('unsupported pages (from a newer version)', () {
    final json = <String, dynamic>{
      'id': 3,
      'format': 'markdown_v9',
      'word_count': 1,
      'character_count': 4,
      'markdown': '### Future\n\nbody',
      'something_new': {'a': 1},
    };

    test('are kept exactly as stored', () {
      final page = StoryPageDbModel.fromJson(json);
      expect(page.isUnsupported, isTrue);
      expect(page.isLegacy, isFalse);
      expect(page.toJson(), json);
      expect(page.toMarkdownPage(), same(page));
    });

    test('still read, best effort, for showing', () {
      final page = StoryPageDbModel.fromJson(json);
      expect(page.title, 'Future');
    });
  });

  test('copyWith changes counts and keeps the content as stored', () {
    final legacy = StoryPageDbModel.fromJson(legacyJson).copyWith(wordCount: 9);
    expect(legacy.isLegacy, isTrue);
    expect(legacy.wordCount, 9);
    expect(legacy.quillBody, legacyJson['body']);

    final markdown = StoryPageDbModel.markdown(id: 2, markdown: '### A').copyWith(characterCount: 1);
    expect(markdown.markdown, '### A');
    expect(markdown.characterCount, 1);
  });

  group('StoryContentDbModel.convertLegacyPages', () {
    StoryContentDbModel contentOf(List<StoryPageDbModel> pages) {
      final result = GenerateBodyPlainTextService.call(pages)!;
      return StoryContentDbModel.create().copyWith(
        title: pages.first.title,
        plainText: result.plainText,
        richPages: result.richPagesWithCounts,
      );
    }

    final second = StoryPageDbModel.legacy(
      id: 2,
      title: 'Day two',
      body: [
        {'insert': 'Rain.\n'},
      ],
    );

    test('converts every page, keeping the title, plain text and counts', () {
      final content = contentOf([StoryPageDbModel.fromJson(legacyJson), second]);
      final converted = content.convertLegacyPages()!;

      expect(converted.hasLegacyPages, isFalse);
      expect(converted.richPages!.map((page) => page.format), everyElement(StoryPageFormat.markdownV1));
      expect(converted.title, content.title);
      expect(converted.plainText, content.plainText);
      expect(converted.wordCount, content.wordCount);
      expect(converted.characterCount, content.characterCount);
      expect(converted.id, content.id);
      expect(converted.createdAt, content.createdAt);
    });

    test('two copies converted separately still compare as unchanged', () {
      final content = contentOf([StoryPageDbModel.fromJson(legacyJson), second]);
      final draft = StoryContentDbModel.dublicate(content);
      expect(draft.convertLegacyPages()!.hasChanges(content.convertLegacyPages()!), isFalse);
    });

    test('nothing to convert: null', () {
      final content = contentOf([StoryPageDbModel.markdown(id: 1, markdown: '### A')]);
      expect(content.convertLegacyPages(), isNull);
    });

    test('a page that would lose formatting keeps the whole content as stored', () {
      final lossy = StoryPageDbModel.legacy(
        id: 3,
        title: null,
        body: [
          {
            'insert': 'big',
            'attributes': {'size': 'large'},
          },
          {'insert': '\n'},
        ],
      );
      expect(contentOf([StoryPageDbModel.fromJson(legacyJson), lossy]).convertLegacyPages(), isNull);
    });

    test('content with a page from a newer version is never converted', () {
      final unsupported = StoryPageDbModel.fromJson(const {'id': 9, 'format': 'markdown_v9', 'markdown': 'x'});
      final content = contentOf([StoryPageDbModel.fromJson(legacyJson), unsupported]);
      expect(content.hasUnsupportedPages, isTrue);
      expect(content.convertLegacyPages(), isNull);
    });
  });
}
