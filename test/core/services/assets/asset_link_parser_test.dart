import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/assets/asset_link_parser.dart';

void main() {
  group('AssetLinkParser', () {
    group('extractIds', () {
      test('returns empty set for null input', () {
        expect(AssetLinkParser.extractIds(null), isEmpty);
      });

      test('returns empty set for empty list', () {
        expect(AssetLinkParser.extractIds([]), isEmpty);
      });

      test('extracts ID from a single image embed', () {
        final body = [
          {
            'insert': {'image': 'images/1762500783746.jpg'},
          },
        ];
        expect(AssetLinkParser.extractIds(body), {1762500783746});
      });

      test('extracts IDs from multiple embeds', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg'},
          },
          {
            'insert': {'audio': 'audio/222.m4a'},
          },
        ];
        expect(AssetLinkParser.extractIds(body), {111, 222});
      });

      // --- Album format ---

      test('extracts all IDs from a pipe-delimited album embed', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg|images/222.jpg|images/333.jpg'},
          },
        ];
        expect(AssetLinkParser.extractIds(body), {111, 222, 333});
      });

      test('ignores empty segments from trailing pipe', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg|'},
          },
        ];
        expect(AssetLinkParser.extractIds(body), {111});
      });

      test('deduplicates IDs across single and album embeds', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg'},
          },
          {
            'insert': {'image': 'images/111.jpg|images/222.jpg'},
          },
        ];
        expect(AssetLinkParser.extractIds(body), {111, 222});
      });

      test('ignores non-integer path segments', () {
        final body = [
          {
            'insert': {'image': 'https://example.com/photo.jpg'},
          },
        ];
        expect(AssetLinkParser.extractIds(body), isEmpty);
      });

      test('ignores plain text nodes', () {
        final body = [
          {'insert': 'Hello World'},
        ];
        expect(AssetLinkParser.extractIds(body), isEmpty);
      });
    });

    group('extractEmbedSources', () {
      test('returns empty list for null input', () {
        expect(AssetLinkParser.extractEmbedSources(null, 'image'), isEmpty);
      });

      test('returns empty list for empty body', () {
        expect(AssetLinkParser.extractEmbedSources([], 'image'), isEmpty);
      });

      test('extracts single image path', () {
        final body = [
          {
            'insert': {'image': 'images/123.jpg'},
          },
        ];
        expect(AssetLinkParser.extractEmbedSources(body, 'image'), ['images/123.jpg']);
      });

      test('extracts external URL', () {
        final body = [
          {
            'insert': {'image': 'https://example.com/photo.jpg'},
          },
        ];
        expect(AssetLinkParser.extractEmbedSources(body, 'image'), ['https://example.com/photo.jpg']);
      });

      // --- Album format ---

      test('splits pipe-delimited album into individual paths', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg|images/222.jpg|images/333.jpg'},
          },
        ];
        expect(
          AssetLinkParser.extractEmbedSources(body, 'image'),
          ['images/111.jpg', 'images/222.jpg', 'images/333.jpg'],
        );
      });

      test('ignores empty segments in pipe-delimited value', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg|'},
          },
        ];
        expect(AssetLinkParser.extractEmbedSources(body, 'image'), ['images/111.jpg']);
      });

      test('does not cross-contaminate audio embeds when querying image', () {
        final body = [
          {
            'insert': {'image': 'images/111.jpg'},
          },
          {
            'insert': {'audio': 'audio/222.m4a'},
          },
        ];
        expect(AssetLinkParser.extractEmbedSources(body, 'image'), ['images/111.jpg']);
        expect(AssetLinkParser.extractEmbedSources(body, 'audio'), ['audio/222.m4a']);
      });

      test('collects paths from multiple album embeds in order', () {
        final body = [
          {
            'insert': {'image': 'images/1.jpg|images/2.jpg'},
          },
          {
            'insert': {'image': 'images/3.jpg'},
          },
        ];
        expect(
          AssetLinkParser.extractEmbedSources(body, 'image'),
          ['images/1.jpg', 'images/2.jpg', 'images/3.jpg'],
        );
      });
    });
  });
}
