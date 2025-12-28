import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/types/support_directory_path.dart';

void main() {
  late Directory testSupportDir;

  setUpAll(() async {
    // Create a temporary directory for testing (once for all tests)
    testSupportDir = await Directory.systemTemp.createTemp('storypad_test_');
    kSupportDirectory = testSupportDir;
  });

  tearDownAll(() async {
    // Clean up test directory
    if (await testSupportDir.exists()) {
      await testSupportDir.delete(recursive: true);
    }
  });

  group('SupportDirectoryPath', () {
    group('relativePath', () {
      test('tmp returns correct relative path', () {
        expect(SupportDirectoryPath.tmp.relativePath, equals('tmp'));
      });

      test('objectbox returns correct relative path', () {
        expect(SupportDirectoryPath.objectbox.relativePath, equals('database/objectbox'));
      });

      test('images returns correct relative path', () {
        expect(SupportDirectoryPath.images.relativePath, equals('images'));
      });

      test('audio returns correct relative path', () {
        expect(SupportDirectoryPath.audio.relativePath, equals('audio'));
      });

      test('backups returns correct relative path', () {
        expect(SupportDirectoryPath.backups.relativePath, equals('backups'));
      });

      test('export_assets returns correct relative path', () {
        expect(SupportDirectoryPath.export_assets.relativePath, equals('export_assets'));
      });

      test('downloaded_from_firestore returns correct relative path', () {
        expect(
          SupportDirectoryPath.downloaded_from_firestore.relativePath,
          equals('downloaded_from_firestore'),
        );
      });
    });

    group('directoryPath', () {
      test('returns directory path string', () {
        final path = SupportDirectoryPath.tmp.directoryPath;
        expect(path, isA<String>());
        expect(path, contains('tmp'));
      });

      test('all paths contain support directory base', () {
        for (final dirPath in SupportDirectoryPath.values) {
          final fullPath = dirPath.directoryPath;
          expect(fullPath, contains(kSupportDirectory.path));
        }
      });
    });

    group('directory getter', () {
      test('returns Directory instance', () {
        final dir = SupportDirectoryPath.tmp.directory;
        expect(dir, isA<Directory>());
      });

      test('directory path includes relative path', () {
        final dir = SupportDirectoryPath.images.directory;
        expect(dir.path, contains('images'));
      });
    });

    group('ensureDirectoryExists', () {
      test('creates directory recursively if it does not exist', () async {
        const dir = SupportDirectoryPath.tmp;

        expect(await dir.directory.exists(), isFalse);

        await dir.ensureDirectoryExists();
        expect(await dir.directory.exists(), isTrue);
      });

      test('handles case when directory already exists', () async {
        const dir = SupportDirectoryPath.tmp;
        // Ensure directory exists
        await dir.ensureDirectoryExists();
        expect(await dir.directory.exists(), isTrue);

        // Calling again should not throw
        await dir.ensureDirectoryExists();
        expect(await dir.directory.exists(), isTrue);
      });

      test('creates nested directories with recursive flag', () async {
        const dir = SupportDirectoryPath.objectbox;

        expect(await dir.directory.exists(), isFalse);

        await dir.ensureDirectoryExists();
        expect(await dir.directory.exists(), isTrue);
      });
    });

    group('all enum cases', () {
      test('have unique relative paths', () {
        final paths = SupportDirectoryPath.values.map((e) => e.relativePath).toList();
        expect(paths.length, equals(paths.toSet().length));
      });

      test('all enum cases can be instantiated', () {
        for (final dirPath in SupportDirectoryPath.values) {
          expect(dirPath.relativePath, isA<String>());
          expect(dirPath.directoryPath, isA<String>());
          expect(dirPath.directory, isA<Directory>());
        }
      });
    });
  });
}
