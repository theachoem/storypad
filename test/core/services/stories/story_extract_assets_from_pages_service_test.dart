import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/stories/story_extract_assets_from_pages_service.dart';

void main() {
  group('StoryExtractAssetsFromPagesService', () {
    group('call()', () {
      test('returns empty set when pages is null', () {
        final result = StoryExtractAssetsFromPagesService.call(null);
        expect(result, isEmpty);
      });

      test('returns empty set when pages is empty', () {
        final result = StoryExtractAssetsFromPagesService.call([]);
        expect(result, isEmpty);
      });

      test('extracts single image asset ID', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/12345',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {12345});
      });

      test('extracts single audio asset ID', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'audio': 'storypad://audio/67890',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {67890});
      });

      test('extracts multiple asset IDs of different types', () {
        final pages = [
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
                'video': 'storypad://assets/333',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {111, 222, 333});
      });

      test('extracts assets from multiple pages', () {
        final pages = [
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
                'audio': 'storypad://audio/200',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {100, 200});
      });

      test('handles duplicate asset IDs (returns unique set)', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/999',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/999',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {999});
        expect(result.length, 1);
      });

      test('ignores non-storypad asset links', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': 'https://example.com/image.jpg',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/123',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {123});
      });

      test('supports both storypad://assets/ (images) and storypad://audio/ prefixes', () {
        final pages = [
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
            {
              'insert': {
                'audio': 'storypad://audio/444',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {111, 222, 333, 444});
      });

      test('ignores non-string embed values', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': {'url': 'storypad://assets/123'},
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/456',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {456});
      });

      test('handles malformed asset IDs gracefully', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/abc',
              },
            },
            {
              'insert': {
                'audio': 'storypad://audio/123',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {123});
      });

      test('ignores nodes without insert map', () {
        final pages = [
          _createPageWithBody([
            {'text': 'just text'},
            {
              'insert': {
                'image': 'storypad://assets/123',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {123});
      });

      test('ignores nodes with insert that is not a map', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': 'just a string',
            },
            {
              'insert': {
                'audio': 'storypad://audio/456',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {456});
      });

      test('ignores non-map nodes', () {
        final pages = [
          _createPageWithBody([
            'just a string',
            {
              'insert': {
                'image': 'storypad://assets/789',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {789});
      });

      test('handles page with null body', () {
        final page = StoryPageDbModel(
          id: 1,
          title: 'page1',
          body: null,
        );

        final result = StoryExtractAssetsFromPagesService.call([page]);

        expect(result, isEmpty);
      });

      test('handles page with empty body', () {
        final pages = [_createPageWithBody([])];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, isEmpty);
      });

      test('extracts large asset IDs correctly', () {
        const largeId = 9223372036854775807; // Max int64
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/$largeId',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {largeId});
      });

      test('extracts assets with multiple embed types in single insert', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'image': 'storypad://assets/111',
                'audio': 'storypad://assets/222',
                'attributes': {'bold': true},
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {111, 222});
      });

      test('handles complex nested structure', () {
        final pages = [
          _createPageWithBody([
            {
              'insert': {
                'text': 'Some text',
                'attributes': {
                  'bold': true,
                  'italic': false,
                },
              },
            },
            {
              'insert': {
                'image': 'storypad://assets/100',
              },
            },
            {
              'insert': {
                'audio': 'storypad://assets/200',
              },
            },
            {
              'insert': {
                'text': 'More text',
              },
            },
          ]),
          _createPageWithBody([
            {
              'insert': {
                'video': 'storypad://assets/300',
              },
            },
          ]),
        ];

        final result = StoryExtractAssetsFromPagesService.call(pages);

        expect(result, {100, 200, 300});
      });
    });
  });
}

/// Helper to create a StoryPageDbModel with body content
StoryPageDbModel _createPageWithBody(List<dynamic> body) {
  return StoryPageDbModel(
    id: DateTime.now().millisecondsSinceEpoch,
    title: 'page-test',
    body: body,
  );
}
