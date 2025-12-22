import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/asset_file_matcher_service.dart';

void main() {
  group('AssetFileMatcherService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('asset_matcher_test');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('matches assets with files by creation time', () async {
      final baseTime = DateTime(2024, 1, 15, 22, 19, 0);

      // Create test files at specific times
      final file1 = await _createFileAtTime(tempDir, '1.m4a', baseTime.add(const Duration(seconds: 43)));
      final file2 = await _createFileAtTime(tempDir, '2.m4a', baseTime.add(const Duration(seconds: 47)));
      final file3 = await _createFileAtTime(tempDir, '3.m4a', baseTime.add(const Duration(seconds: 50)));
      final file4 = await _createFileAtTime(tempDir, '4.m4a', baseTime.add(const Duration(seconds: 55)));
      final file5 = await _createFileAtTime(tempDir, '5.m4a', baseTime.add(const Duration(seconds: 66)));

      // Create test assets
      final assets = [
        _createAsset(1, baseTime.add(const Duration(seconds: 43)), '/audio/1.m4a'),
        _createAsset(2, baseTime.add(const Duration(seconds: 47)), '/audio/2.m4a'),
        _createAsset(3, baseTime.add(const Duration(seconds: 50)), '/audio/3.m4a'),
        _createAsset(4, baseTime.add(const Duration(seconds: 55)), '/audio/4.m4a'),
        _createAsset(5, baseTime.add(const Duration(seconds: 66)), '/audio/5.m4a'),
      ];

      final matches = await AssetFileMatcherService.matchAssets(
        assets: assets,
        availableFiles: [file1, file2, file3, file4, file5],
      );

      expect(matches.length, 5);
      expect(matches[assets[0]]?.path, file1.path);
      expect(matches[assets[1]]?.path, file2.path);
      expect(matches[assets[2]]?.path, file3.path);
      expect(matches[assets[3]]?.path, file4.path);
      expect(matches[assets[4]]?.path, file5.path);
    });

    test('matches assets within 30-second tolerance', () async {
      final baseTime = DateTime.now();

      final file1 = await _createFileAtTime(tempDir, '1.m4a', baseTime);
      final file2 = await _createFileAtTime(tempDir, '2.m4a', baseTime.add(const Duration(seconds: 25)));

      final assets = [
        _createAsset(1, baseTime.add(const Duration(seconds: 5)), '/audio/1.m4a'),
        _createAsset(2, baseTime.add(const Duration(seconds: 30)), '/audio/2.m4a'),
      ];

      final matches = await AssetFileMatcherService.matchAssets(
        assets: assets,
        availableFiles: [file1, file2],
      );

      expect(matches.length, 2);
      expect(matches[assets[0]]?.path, file1.path);
      expect(matches[assets[1]]?.path, file2.path);
    });

    test('does not match files outside 30-second tolerance', () async {
      final baseTime = DateTime.now();

      final file1 = await _createFileAtTime(tempDir, '1.m4a', baseTime);

      final assets = [
        _createAsset(1, baseTime.add(const Duration(seconds: 45)), '/audio/1.m4a'),
      ];

      final matches = await AssetFileMatcherService.matchAssets(
        assets: assets,
        availableFiles: [file1],
      );

      expect(matches.length, 0);
    });

    test('matches by file extension', () async {
      final baseTime = DateTime.now();

      final file1 = await _createFileAtTime(tempDir, '1.m4a', baseTime);
      final file2 = await _createFileAtTime(tempDir, '2.mp3', baseTime);
      final file3 = await _createFileAtTime(tempDir, '3.wav', baseTime);

      final assets = [
        _createAsset(1, baseTime, '/audio/1.m4a'),
        _createAsset(2, baseTime, '/audio/2.mp3'),
        _createAsset(3, baseTime, '/audio/3.wav'),
      ];

      final matches = await AssetFileMatcherService.matchAssets(
        assets: assets,
        availableFiles: [file1, file2, file3],
      );

      expect(matches.length, 3);
      expect(matches[assets[0]]?.path, file1.path);
      expect(matches[assets[1]]?.path, file2.path);
      expect(matches[assets[2]]?.path, file3.path);
    });

    test('avoids duplicate matches', () async {
      final baseTime = DateTime.now();

      final file1 = await _createFileAtTime(tempDir, '1.m4a', baseTime);

      final assets = [
        _createAsset(1, baseTime, '/audio/1.m4a'),
        _createAsset(2, baseTime.add(const Duration(seconds: 1)), '/audio/2.m4a'),
      ];

      final matches = await AssetFileMatcherService.matchAssets(
        assets: assets,
        availableFiles: [file1],
      );

      expect(matches.length, 1);
      expect(matches[assets[0]]?.path, file1.path);
      expect(matches[assets[1]], isNull);
    });

    test('handles empty inputs', () async {
      final matches = await AssetFileMatcherService.matchAssets(
        assets: [],
        availableFiles: [],
      );

      expect(matches.length, 0);
    });
  });
}

/// Helper to create a file with specific modified time
Future<File> _createFileAtTime(Directory dir, String name, DateTime time) async {
  final file = File('${dir.path}/$name');
  await file.writeAsString('test content');

  // Set the file's modification time to match the desired time
  await file.setLastModified(time);

  return file;
}

/// Helper to create a test asset
AssetDbModel _createAsset(int id, DateTime createdAt, String source) {
  return AssetDbModel.fromLocalPath(
    id: id,
    localPath: source,
    type: .audio,
    createdAt: createdAt,
  );
}
