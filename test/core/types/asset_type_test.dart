import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/types/asset_type.dart';

void main() {
  group('AssetType - Enum Values', () {
    test('has image and audio types', () {
      expect(AssetType.values, hasLength(2));
      expect(AssetType.values, contains(AssetType.image));
      expect(AssetType.values, contains(AssetType.audio));
    });

    test('image type has correct properties', () {
      expect(AssetType.image.name, equals('image'));
      expect(AssetType.image.embedLinkPath, equals('assets'));
      expect(AssetType.image.subDirectory, equals('images'));
    });

    test('audio type has correct properties', () {
      expect(AssetType.audio.name, equals('audio'));
      expect(AssetType.audio.embedLinkPath, equals('audio'));
      expect(AssetType.audio.subDirectory, equals('audio'));
    });
  });

  group('AssetType - embedLinkPrefix', () {
    test('generates correct prefix for image', () {
      expect(AssetType.image.embedLinkPrefix, equals('storypad://assets/'));
    });

    test('generates correct prefix for audio', () {
      expect(AssetType.audio.embedLinkPrefix, equals('storypad://audio/'));
    });

    test('prefix always ends with slash', () {
      for (final type in AssetType.values) {
        expect(type.embedLinkPrefix, endsWith('/'));
      }
    });

    test('prefix always starts with storypad://', () {
      for (final type in AssetType.values) {
        expect(type.embedLinkPrefix, startsWith('storypad://'));
      }
    });
  });

  group('AssetType - buildEmbedLink', () {
    test('builds correct image embed link', () {
      const id = 1762500783746;
      expect(
        AssetType.image.buildEmbedLink(id),
        equals('storypad://assets/1762500783746'),
      );
    });

    test('builds correct audio embed link', () {
      const id = 1762500783747;
      expect(
        AssetType.audio.buildEmbedLink(id),
        equals('storypad://audio/1762500783747'),
      );
    });

    test('handles various ID values', () {
      final testIds = [1, 100, 999999, 1762500783746];
      for (final id in testIds) {
        expect(
          AssetType.image.buildEmbedLink(id),
          equals('storypad://assets/$id'),
        );
        expect(
          AssetType.audio.buildEmbedLink(id),
          equals('storypad://audio/$id'),
        );
      }
    });
  });

  group('AssetType - subDirectory property', () {
    test('image uses images subdirectory', () {
      expect(AssetType.image.subDirectory, equals('images'));
    });

    test('audio uses audio subdirectory', () {
      expect(AssetType.audio.subDirectory, equals('audio'));
    });

    test('subdirectories match storage paths structure', () {
      // The getStoragePath method uses subDirectory in its path construction
      // verify the subDirectory values are correctly set
      expect(
        AssetType.image.subDirectory,
        isNotEmpty,
      );
      expect(
        AssetType.audio.subDirectory,
        isNotEmpty,
      );
    });
  });

  group('AssetType - fromValue', () {
    test('returns image for null value', () {
      expect(AssetType.fromValue(null), equals(AssetType.image));
    });

    test('returns image for "image" value', () {
      expect(AssetType.fromValue('image'), equals(AssetType.image));
    });

    test('returns audio for "audio" value', () {
      expect(AssetType.fromValue('audio'), equals(AssetType.audio));
    });

    test('returns image for unknown value', () {
      expect(AssetType.fromValue('unknown'), equals(AssetType.image));
      expect(AssetType.fromValue('video'), equals(AssetType.image));
    });

    test('is case-sensitive', () {
      // Should return default (image) for incorrect case
      expect(AssetType.fromValue('IMAGE'), equals(AssetType.image));
      expect(AssetType.fromValue('Audio'), equals(AssetType.image));
    });
  });

  group('AssetType - parseAssetIdFromLink', () {
    test('parses image asset ID from valid link', () {
      const link = 'storypad://assets/1762500783746';
      expect(
        AssetType.image.parseAssetIdFromLink(link),
        equals(1762500783746),
      );
    });

    test('parses audio asset ID from valid link', () {
      const link = 'storypad://audio/1762500783747';
      expect(
        AssetType.audio.parseAssetIdFromLink(link),
        equals(1762500783747),
      );
    });

    test('returns null for mismatched type', () {
      const audioLink = 'storypad://audio/123';
      expect(AssetType.image.parseAssetIdFromLink(audioLink), isNull);

      const imageLink = 'storypad://assets/456';
      expect(AssetType.audio.parseAssetIdFromLink(imageLink), isNull);
    });

    test('returns null for invalid link format', () {
      expect(AssetType.image.parseAssetIdFromLink('invalid'), isNull);
      expect(AssetType.image.parseAssetIdFromLink('storypad://assets/'), isNull);
      expect(AssetType.image.parseAssetIdFromLink('storypad://assets/abc'), isNull);
    });

    test('handles edge case IDs', () {
      expect(
        AssetType.image.parseAssetIdFromLink('storypad://assets/0'),
        equals(0),
      );
      expect(
        AssetType.audio.parseAssetIdFromLink('storypad://audio/999999999'),
        equals(999999999),
      );
    });
  });

  group('AssetType - parseAssetId (static convenience method)', () {
    test('parses image link', () {
      const link = 'storypad://assets/1762500783746';
      expect(AssetType.parseAssetId(link), equals(1762500783746));
    });

    test('parses audio link', () {
      const link = 'storypad://audio/1762500783747';
      expect(AssetType.parseAssetId(link), equals(1762500783747));
    });

    test('returns null for invalid link', () {
      expect(AssetType.parseAssetId('invalid://link/123'), isNull);
      expect(AssetType.parseAssetId('storypad://unknown/123'), isNull);
      expect(AssetType.parseAssetId('not a link'), isNull);
    });

    test('handles various valid links', () {
      final testLinks = [
        ('storypad://assets/1', 1),
        ('storypad://assets/999', 999),
        ('storypad://audio/1', 1),
        ('storypad://audio/999', 999),
      ];

      for (final (link, expectedId) in testLinks) {
        expect(AssetType.parseAssetId(link), equals(expectedId));
      }
    });
  });

  group('AssetType - getTypeFromLink (static)', () {
    test('identifies image type from link', () {
      const link = 'storypad://assets/123';
      expect(AssetType.getTypeFromLink(link), equals(AssetType.image));
    });

    test('identifies audio type from link', () {
      const link = 'storypad://audio/123';
      expect(AssetType.getTypeFromLink(link), equals(AssetType.audio));
    });

    test('returns null for invalid link', () {
      expect(AssetType.getTypeFromLink('invalid'), isNull);
      expect(AssetType.getTypeFromLink('storypad://unknown/123'), isNull);
    });

    test('matches any valid asset link', () {
      for (final type in AssetType.values) {
        final link = type.buildEmbedLink(123);
        expect(AssetType.getTypeFromLink(link), equals(type));
      }
    });
  });

  group('AssetType - isValidAssetLink (static)', () {
    test('validates image links', () {
      expect(
        AssetType.isValidAssetLink('storypad://assets/123'),
        isTrue,
      );
    });

    test('validates audio links', () {
      expect(
        AssetType.isValidAssetLink('storypad://audio/456'),
        isTrue,
      );
    });

    test('rejects invalid links', () {
      expect(AssetType.isValidAssetLink('invalid'), isFalse);
      expect(AssetType.isValidAssetLink('storypad://unknown/123'), isFalse);
      expect(AssetType.isValidAssetLink('http://example.com'), isFalse);
    });

    test('all buildEmbedLink results are valid', () {
      for (final type in AssetType.values) {
        final link = type.buildEmbedLink(123);
        expect(AssetType.isValidAssetLink(link), isTrue);
      }
    });
  });

  group('AssetType - allEmbedLinkPrefixes (static)', () {
    test('includes all asset type prefixes', () {
      final prefixes = AssetType.allEmbedLinkPrefixes;
      expect(prefixes, hasLength(2));
      expect(prefixes, contains('storypad://assets/'));
      expect(prefixes, contains('storypad://audio/'));
    });

    test('all prefixes are valid', () {
      for (final prefix in AssetType.allEmbedLinkPrefixes) {
        expect(prefix, startsWith('storypad://'));
        expect(prefix, endsWith('/'));
      }
    });
  });

  group('AssetType - Integration Tests', () {
    test('complete workflow for image asset link parsing', () {
      const assetId = 1762500783746;

      // Build link
      final link = AssetType.image.buildEmbedLink(assetId);
      expect(link, equals('storypad://assets/1762500783746'));

      // Validate link
      expect(AssetType.isValidAssetLink(link), isTrue);

      // Get type from link
      final type = AssetType.getTypeFromLink(link);
      expect(type, equals(AssetType.image));

      // Parse ID from link
      final parsedId = AssetType.parseAssetId(link);
      expect(parsedId, equals(assetId));
    });

    test('complete workflow for audio asset link parsing', () {
      const assetId = 1762500783747;

      // Build link
      final link = AssetType.audio.buildEmbedLink(assetId);
      expect(link, equals('storypad://audio/1762500783747'));

      // Validate link
      expect(AssetType.isValidAssetLink(link), isTrue);

      // Get type from link
      final type = AssetType.getTypeFromLink(link);
      expect(type, equals(AssetType.audio));

      // Parse ID from link
      final parsedId = AssetType.parseAssetId(link);
      expect(parsedId, equals(assetId));
    });

    test('type identification consistency', () {
      for (final type in AssetType.values) {
        for (final id in [1, 123, 999999]) {
          final link = type.buildEmbedLink(id);
          expect(AssetType.getTypeFromLink(link), equals(type));
          expect(AssetType.parseAssetId(link), equals(id));
          expect(AssetType.isValidAssetLink(link), isTrue);
        }
      }
    });
  });

  group('AssetType - backward compatibility', () {
    test('image uses assets scheme for backward compatibility', () {
      // Image type deliberately uses 'assets' in URI for backward compatibility
      expect(AssetType.image.embedLinkPath, equals('assets'));
      expect(AssetType.image.subDirectory, equals('images'));

      // This asymmetry is intentional and documented
      expect(
        AssetType.image.embedLinkPrefix,
        isNot(equals('${AssetType.image.subDirectory}/')),
      );
    });

    test('old image links still work', () {
      const oldImageLink = 'storypad://assets/1762500783746';
      expect(AssetType.isValidAssetLink(oldImageLink), isTrue);
      expect(AssetType.parseAssetId(oldImageLink), equals(1762500783746));
      expect(AssetType.getTypeFromLink(oldImageLink), equals(AssetType.image));
    });
  });
}
