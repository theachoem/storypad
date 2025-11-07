import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/stories/story_extract_assets_from_content_service.dart';

void main() {
  group('StoryExtractAssetsFromContentService', () {
    group('images()', () {
      test('returns empty list when content is null', () {
        final result = StoryExtractAssetsFromContentService.images(null);
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
        final result = StoryExtractAssetsFromContentService.images(content);
        expect(result, isEmpty);
      });

      test('extracts single image link', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/12345',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/12345']);
      });

      test('extracts multiple image links', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/111',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/222',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/111', 'storypad://assets/222']);
      });

      test('extracts images from multiple pages', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/100',
              },
            },
          ]),
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/200',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/100', 'storypad://assets/200']);
      });

      test('filters out audio links (storypad://audio/)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/111',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/222',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/333',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/111', 'storypad://assets/333']);
        expect(result, isNot(contains('storypad://audio/222')));
      });

      test('filters out non-storypad links', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'https://example.com/image.jpg',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/123',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/123']);
      });

      test('ignores non-string embed values', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': {'url': 'storypad://assets/123'},
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/456',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/456']);
      });

      test('ignores nodes without insert map', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {'text': 'just text'},
            {
              'insert': {
                'image': 'storypad://assets/123',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/123']);
      });

      test('ignores nodes with insert that is not a map', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': 'just a string',
            },
            {
              'insert': {
                'image': 'storypad://assets/456',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/456']);
      });

      test('ignores non-map nodes', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            'just a string',
            {
              'insert': {
                'image': 'storypad://assets/789',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/789']);
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
        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, isEmpty);
      });

      test('handles page with empty body', () {
        final content = _createContentWithPages([_createPageWithBody([])]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, isEmpty);
      });

      test('handles multiple embed types in single insert (only extracts images)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'text': 'Some text',
                'image': 'storypad://assets/111',
                'audio': 'storypad://audio/222',
                'attributes': {'bold': true},
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/111']);
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
                'image': 'storypad://assets/100',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/200',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/300',
              },
            },
          ]),
          _createPageWithBody([
            {
              'insert': {
                'image': 'https://external.com/img.png',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/400',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/100', 'storypad://assets/300', 'storypad://assets/400']);
      });

      test('preserves order of extracted images', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/999',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/111',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/222',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, orderedEquals(['storypad://assets/999', 'storypad://assets/111', 'storypad://assets/222']));
      });

      test('ignores empty string embed values', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': '',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/123',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.images(content);

        expect(result, ['storypad://assets/123']);
      });
    });

    group('audio()', () {
      test('returns empty list when content is null', () {
        final result = StoryExtractAssetsFromContentService.audio(null);
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
        final result = StoryExtractAssetsFromContentService.audio(content);
        expect(result, isEmpty);
      });

      test('extracts single audio link', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'audio': 'storypad://audio/12345',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.audio(content);

        expect(result, ['storypad://audio/12345']);
      });

      test('extracts multiple audio links', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'audio': 'storypad://audio/111',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/222',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.audio(content);

        expect(result, ['storypad://audio/111', 'storypad://audio/222']);
      });

      test('filters out image links (storypad://assets/)', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'audio': 'storypad://audio/111',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/222',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/333',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.audio(content);

        expect(result, ['storypad://audio/111', 'storypad://audio/333']);
        expect(result, isNot(contains('storypad://assets/222')));
      });
    });

    group('all()', () {
      test('returns empty list when content is null', () {
        final result = StoryExtractAssetsFromContentService.all(null);
        expect(result, isEmpty);
      });

      test('returns both images and audio in order', () {
        final content = _createContentWithPages([
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/100',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/200',
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/300',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/400',
              },
            },
          ]),
        ]);

        final result = StoryExtractAssetsFromContentService.all(content);

        expect(result, [
          'storypad://assets/100',
          'storypad://assets/300',
          'storypad://audio/200',
          'storypad://audio/400',
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
