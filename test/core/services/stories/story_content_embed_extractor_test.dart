import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';

void main() {
  group('StoryContentEmbedExtractor', () {
    group('media()', () {
      test('returns empty list when content is null', () {
        final result = StoryContentEmbedExtractor.media(null);
        expect(result, isEmpty);
      });

      test('returns empty list when content has no pages', () {
        final content = StoryContentDbModel(
          id: 1,
          title: 'Test',
          plainText: 'test',
          createdAt: DateTime.now(),
          pages: [],
          richPages: [],
        );
        final result = StoryContentEmbedExtractor.media(content);
        expect(result, isEmpty);
      });

      test('extracts single image link', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/12345.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/12345.jpg']);
      });

      test('extracts multiple image links', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/111.jpg',
              },
            },
            {
              'insert': {
                'media': 'images/222.png',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/111.jpg', 'images/222.png']);
      });

      test('extracts images from multiple pages', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/100.jpg',
              },
            },
          ]),
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/200.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/100.jpg', 'images/200.jpg']);
      });

      test('filters out audio links (audio/)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/111.jpg',
              },
            },
            {
              'insert': {
                'audio': 'audio/222.m4a',
              },
            },
            {
              'insert': {
                'media': 'images/333.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/111.jpg', 'images/333.jpg']);
        expect(result, isNot(contains('audio/222.m4a')));
      });

      test('includes both local assets and external URLs', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'https://example.com/image.jpg',
              },
            },
            {
              'insert': {
                'media': 'images/123.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['https://example.com/image.jpg', 'images/123.jpg']);
      });

      test('ignores non-string embed values', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': {'url': 'images/123.jpg'},
              },
            },
            {
              'insert': {
                'media': 'images/456.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/456.jpg']);
      });

      test('ignores nodes without insert map', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {'text': 'just text'},
            {
              'insert': {
                'media': 'images/123.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/123.jpg']);
      });

      test('ignores nodes with insert that is not a map', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': 'just a string',
            },
            {
              'insert': {
                'media': 'images/456.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/456.jpg']);
      });

      test('ignores non-map nodes', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            'just a string',
            {
              'insert': {
                'media': 'images/789.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/789.jpg']);
      });

      test('handles page with null body', () {
        final page = StoryPageDbModel(
          id: 1,
          title: 'page1',
          body: null,
        );

        final content = StoryContentDbModel(
          id: 1,
          title: 'Test',
          plainText: 'test',
          createdAt: DateTime.now(),
          pages: [],
          richPages: [page],
        );
        final result = StoryContentEmbedExtractor.media(content);

        expect(result, isEmpty);
      });

      test('handles page with empty body', () {
        final content = _createContentWithPages([_createPageWithBody([])]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, isEmpty);
      });

      test('handles multiple embed types in single insert (only extracts images)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'text': 'Some text',
                'media': 'images/111.jpg',
                'audio': 'audio/222.m4a',
                'attributes': {'bold': true},
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/111.jpg']);
      });

      test('handles complex mixed content', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'text': 'Introduction text',
              },
            },
            {
              'insert': {
                'media': 'images/100.jpg',
              },
            },
            {
              'insert': {
                'audio': 'audio/200.m4a',
              },
            },
            {
              'insert': {
                'media': 'images/300.jpg',
              },
            },
          ]),
          _createPageWithBody([
            {
              'insert': {
                'media': 'https://external.com/img.png',
              },
            },
            {
              'insert': {
                'media': 'images/400.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/100.jpg', 'images/300.jpg', 'https://external.com/img.png', 'images/400.jpg']);
      });

      test('preserves order of extracted images', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/999.jpg',
              },
            },
            {
              'insert': {
                'media': 'images/111.jpg',
              },
            },
            {
              'insert': {
                'media': 'images/222.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, orderedEquals(['images/999.jpg', 'images/111.jpg', 'images/222.jpg']));
      });

      test('filters out empty string embed values', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': '',
              },
            },
            {
              'insert': {
                'media': 'images/123.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/123.jpg']);
      });

      test('reads the legacy `image` key the same as `media`', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'images/legacy.jpg',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, ['images/legacy.jpg']);
      });

      test('preserves order across mixed legacy `image` and current `media` embeds on one page', () {
        // A page can genuinely mix both keys: an untouched legacy embed next
        // to one that was edited (and so upgraded to `media`).
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'images/1.jpg',
              },
            },
            {
              'insert': {
                'media': 'images/2.jpg',
              },
            },
            {
              'insert': {
                'image': 'videos/3.mp4',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.media(content);

        expect(result, orderedEquals(['images/1.jpg', 'images/2.jpg', 'videos/3.mp4']));
      });
    });

    group('audio()', () {
      test('returns empty list when content is null', () {
        final result = StoryContentEmbedExtractor.audio(null);
        expect(result, isEmpty);
      });

      test('returns empty list when content has no pages', () {
        final content = StoryContentDbModel(
          id: 1,
          title: 'Test',
          plainText: 'test',
          createdAt: DateTime.now(),
          pages: [],
          richPages: [],
        );
        final result = StoryContentEmbedExtractor.audio(content);
        expect(result, isEmpty);
      });

      test('extracts single audio link', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'audio': 'audio/12345.m4a',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.audio(content);

        expect(result, ['audio/12345.m4a']);
      });

      test('extracts multiple audio links', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'audio': 'audio/111.m4a',
              },
            },
            {
              'insert': {
                'audio': 'audio/222.m4a',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.audio(content);

        expect(result, ['audio/111.m4a', 'audio/222.m4a']);
      });

      test('filters out image links (images/)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'audio': 'audio/111.m4a',
              },
            },
            {
              'insert': {
                'media': 'images/222.jpg',
              },
            },
            {
              'insert': {
                'audio': 'audio/333.m4a',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.audio(content);

        expect(result, ['audio/111.m4a', 'audio/333.m4a']);
        expect(result, isNot(contains('images/222.jpg')));
      });
    });

    group('photos() / videos()', () {
      test('returns empty lists when content is null', () {
        expect(StoryContentEmbedExtractor.photos(null), isEmpty);
        expect(StoryContentEmbedExtractor.videos(null), isEmpty);
      });

      test('splits the image embed into photos and videos by path', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/100.jpg',
              },
            },
            {
              'insert': {
                'media': 'videos/200.mp4',
              },
            },
            {
              'insert': {
                'media': 'images/300.jpg',
              },
            },
            {
              'insert': {
                'media': 'videos/400.mp4',
              },
            },
          ]),
        ]);

        expect(StoryContentEmbedExtractor.photos(content), ['images/100.jpg', 'images/300.jpg']);
        expect(StoryContentEmbedExtractor.videos(content), ['videos/200.mp4', 'videos/400.mp4']);
      });

      test('media() still returns the union (photos and videos together)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/1.jpg',
              },
            },
            {
              'insert': {
                'media': 'videos/2.mp4',
              },
            },
          ]),
        ]);

        expect(StoryContentEmbedExtractor.media(content), ['images/1.jpg', 'videos/2.mp4']);
      });

      test('external URLs are treated as photos, not videos', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'https://example.com/image.jpg',
              },
            },
          ]),
        ]);

        expect(StoryContentEmbedExtractor.photos(content), ['https://example.com/image.jpg']);
        expect(StoryContentEmbedExtractor.videos(content), isEmpty);
      });
    });

    group('all()', () {
      test('returns empty list when content is null', () {
        final result = StoryContentEmbedExtractor.all(null);
        expect(result, isEmpty);
      });

      test('returns photos, videos, and audio in that order', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'media': 'images/100.jpg',
              },
            },
            {
              'insert': {
                'audio': 'audio/200.m4a',
              },
            },
            {
              'insert': {
                'media': 'videos/250.mp4',
              },
            },
            {
              'insert': {
                'media': 'images/300.jpg',
              },
            },
            {
              'insert': {
                'audio': 'audio/400.m4a',
              },
            },
          ]),
        ]);

        final result = StoryContentEmbedExtractor.all(content);

        expect(result, [
          'images/100.jpg',
          'images/300.jpg',
          'videos/250.mp4',
          'audio/200.m4a',
          'audio/400.m4a',
        ]);
      });
    });
  });
}

/// Helper to create a StoryContentDbModel with pages
StoryContentDbModel _createContentWithPages(List<StoryPageDbModel> pages) {
  return StoryContentDbModel(
    id: 1,
    title: 'Test Story',
    plainText: 'test',
    createdAt: DateTime.now(),
    pages: [],
    richPages: pages,
  );
}

/// Helper to create a StoryPageDbModel with body content
StoryPageDbModel _createPageWithBody(List<dynamic> body) {
  return StoryPageDbModel(
    id: DateTime.now().millisecondsSinceEpoch,
    title: 'page-test',
    body: body,
  );
}
