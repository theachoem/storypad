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
      expect(AssetType.image.subDirectory.relativePath, equals('images'));
    });

    test('audio type has correct properties', () {
      expect(AssetType.audio.name, equals('audio'));
      expect(AssetType.audio.subDirectory.relativePath, equals('audio'));
    });
  });

  group('AssetType - subDirectory property', () {
    test('image uses images subdirectory', () {
      expect(AssetType.image.subDirectory.relativePath, equals('images'));
    });

    test('audio uses audio subdirectory', () {
      expect(AssetType.audio.subDirectory.relativePath, equals('audio'));
    });

    test('subdirectories match storage paths structure', () {
      // The getStoragePath method uses subDirectory in its path construction
      // verify the subDirectory values are correctly set
      expect(
        AssetType.image.subDirectory.relativePath,
        isNotEmpty,
      );
      expect(
        AssetType.audio.subDirectory.relativePath,
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

  group('AssetType - getRelativeStoragePath', () {
    test('generates correct relative path for image', () {
      const id = 1762500783746;
      const extension = '.jpg';
      expect(
        AssetType.image.getRelativeStoragePath(id: id, extension: extension),
        equals('images/1762500783746.jpg'),
      );
    });

    test('generates correct relative path for audio', () {
      const id = 1762500783747;
      const extension = '.m4a';
      expect(
        AssetType.audio.getRelativeStoragePath(id: id, extension: extension),
        equals('audio/1762500783747.m4a'),
      );
    });

    test('handles various extensions', () {
      const testData = [
        ('.jpg', 'images/123.jpg'),
        ('.png', 'images/123.png'),
        ('.gif', 'images/123.gif'),
      ];

      for (final (extension, expected) in testData) {
        expect(
          AssetType.image.getRelativeStoragePath(id: 123, extension: extension),
          equals(expected),
        );
      }
    });
  });

  group('AssetType - parseAssetId (static method)', () {
    test('parses image asset ID from relative path', () {
      const path = 'images/1762500783746.jpg';
      expect(AssetType.parseAssetId(path), equals(1762500783746));
    });

    test('parses audio asset ID from relative path', () {
      const path = 'audio/1762500783747.m4a';
      expect(AssetType.parseAssetId(path), equals(1762500783747));
    });

    test('returns null for invalid path format', () {
      expect(AssetType.parseAssetId('invalid'), isNull);
      expect(AssetType.parseAssetId('images/'), isNull);
      expect(AssetType.parseAssetId('images/abc.jpg'), isNull);
    });

    test('handles edge case IDs', () {
      expect(
        AssetType.parseAssetId('images/0.jpg'),
        equals(0),
      );
      expect(
        AssetType.parseAssetId('audio/999999999.m4a'),
        equals(999999999),
      );
    });

    test('handles paths without extensions', () {
      expect(
        AssetType.parseAssetId('images/123'),
        equals(123),
      );
      expect(
        AssetType.parseAssetId('audio/456'),
        equals(456),
      );
    });
  });

  group('AssetType - getTypeFromLink (static)', () {
    test('identifies image type from relative path', () {
      const path = 'images/123.jpg';
      expect(AssetType.getTypeFromLink(path), equals(AssetType.image));
    });

    test('identifies audio type from relative path', () {
      const path = 'audio/123.m4a';
      expect(AssetType.getTypeFromLink(path), equals(AssetType.audio));
    });

    test('returns null for invalid path', () {
      expect(AssetType.getTypeFromLink('invalid'), isNull);
      expect(AssetType.getTypeFromLink('unknown/123.jpg'), isNull);
    });

    test('matches any valid asset path by subdirectory', () {
      for (final type in AssetType.values) {
        final path = type.getRelativeStoragePath(id: 123, extension: '.ext');
        expect(AssetType.getTypeFromLink(path), equals(type));
      }
    });
  });

  group('AssetType - Integration Tests', () {
    test('complete workflow for image asset path', () {
      const assetId = 1762500783746;
      const extension = '.jpg';

      // Generate relative path
      final path = AssetType.image.getRelativeStoragePath(
        id: assetId,
        extension: extension,
      );
      expect(path, equals('images/1762500783746.jpg'));

      // Get type from path
      final type = AssetType.getTypeFromLink(path);
      expect(type, equals(AssetType.image));

      // Parse ID from path
      final parsedId = AssetType.parseAssetId(path);
      expect(parsedId, equals(assetId));
    });

    test('complete workflow for audio asset path', () {
      const assetId = 1762500783747;
      const extension = '.m4a';

      // Generate relative path
      final path = AssetType.audio.getRelativeStoragePath(
        id: assetId,
        extension: extension,
      );
      expect(path, equals('audio/1762500783747.m4a'));

      // Get type from path
      final type = AssetType.getTypeFromLink(path);
      expect(type, equals(AssetType.audio));

      // Parse ID from path
      final parsedId = AssetType.parseAssetId(path);
      expect(parsedId, equals(assetId));
    });

    test('type identification consistency', () {
      for (final type in AssetType.values) {
        for (final id in [1, 123, 999999]) {
          final path = type.getRelativeStoragePath(id: id, extension: '.ext');
          expect(AssetType.getTypeFromLink(path), equals(type));
          expect(AssetType.parseAssetId(path), equals(id));
        }
      }
    });
  });

  group('AssetType - Storage paths', () {
    test('getRelativeStoragePath returns relative path', () {
      final path = AssetType.image.getRelativeStoragePath(id: 123, extension: '.jpg');
      // Should start with subDirectory, not an absolute path
      expect(path, equals('images/123.jpg'));
      expect(path, isNot(startsWith('/')));
    });

    test('getRelativeStoragePath works for audio', () {
      final path = AssetType.audio.getRelativeStoragePath(id: 456, extension: '.m4a');
      expect(path, equals('audio/456.m4a'));
      expect(path, isNot(startsWith('/')));
    });
  });
}
