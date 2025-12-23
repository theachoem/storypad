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

    test('matches file created 7 minutes after asset (long recording)', () async {
      // Scenario: Asset created at 11:50pm, file created at 11:57pm (7 min recording)
      final assetTime = DateTime(2024, 1, 15, 23, 50, 0);
      final fileTime = DateTime(2024, 1, 15, 23, 57, 0);

      final file = await _createFileAtTime(tempDir, 'recording.m4a', fileTime);
      final asset = _createAsset(1, assetTime, '/audio/1.m4a');

      final matches = await AssetFileMatcherService.matchAssets(
        assets: [asset],
        availableFiles: [file],
      );

      expect(matches.length, 1);
      expect(matches[asset]?.path, file.path);
    });

    test('matches file created 1 hour after asset (very long recording)', () async {
      // Scenario: Asset created at 10:00pm, file created at 11:00pm (1 hour recording)
      final assetTime = DateTime(2024, 1, 15, 22, 0, 0);
      final fileTime = DateTime(2024, 1, 15, 23, 0, 0);

      final file = await _createFileAtTime(tempDir, 'recording.m4a', fileTime);
      final asset = _createAsset(1, assetTime, '/audio/1.m4a');

      final matches = await AssetFileMatcherService.matchAssets(
        assets: [asset],
        availableFiles: [file],
      );

      expect(matches.length, 1);
      expect(matches[asset]?.path, file.path);
    });

    test('matches files in sequential order', () async {
      final baseTime = DateTime.now();

      // Assets created first
      final asset1Time = baseTime;
      final asset2Time = baseTime.add(const Duration(seconds: 10));
      final asset3Time = baseTime.add(const Duration(seconds: 20));

      // Files created after (in order, but with varying delays)
      final file1 = await _createFileAtTime(tempDir, '1.m4a', baseTime.add(const Duration(seconds: 5)));
      final file2 = await _createFileAtTime(
        tempDir,
        '2.m4a',
        baseTime.add(const Duration(minutes: 15)),
      ); // 15 min later
      final file3 = await _createFileAtTime(tempDir, '3.m4a', baseTime.add(const Duration(hours: 1))); // 1 hour later

      final assets = [
        _createAsset(1, asset1Time, '/audio/1.m4a'),
        _createAsset(2, asset2Time, '/audio/2.m4a'),
        _createAsset(3, asset3Time, '/audio/3.m4a'),
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

    test('skips files created before asset', () async {
      final baseTime = DateTime.now();

      // File created BEFORE asset - should skip
      final fileBefore = await _createFileAtTime(tempDir, '1.m4a', baseTime.subtract(const Duration(seconds: 10)));
      // File created AFTER asset - should match
      final fileAfter = await _createFileAtTime(tempDir, '2.m4a', baseTime.add(const Duration(seconds: 5)));

      final asset = _createAsset(1, baseTime, '/audio/1.m4a');

      final matches = await AssetFileMatcherService.matchAssets(
        assets: [asset],
        availableFiles: [fileBefore, fileAfter],
      );

      expect(matches.length, 1);
      expect(matches[asset]?.path, fileAfter.path);
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
