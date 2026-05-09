import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/assets/import_media_from_tar_service.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:tar/tar.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a real in-memory `.tar.gz` stream from the provided [entries].
/// Each entry is a (path, bytes) pair.
///
/// This produces the **exact same byte format** as a `.tar.gz` file on disk —
/// the bytes pass through the real [tarWriter] and [gzip.encoder] transformers,
/// so the service's [gzip.decoder] + [TarReader] pipeline sees no difference.
///
/// The only distinction from production (`File(path).openRead()`) is that the
/// bytes originate from memory rather than disk. This avoids needing a temp
/// directory in every test while keeping the parsing logic fully exercised.
/// For tests that should be as close to production as possible, use a real
/// file and call `file.openRead()` directly (see the "real .tar.gz file" group).
Stream<List<int>> _buildTarGz(List<(String, List<int>)> entries) {
  final controller = StreamController<TarEntry>();

  Future(() async {
    for (final (path, bytes) in entries) {
      controller.add(
        TarEntry.data(
          TarHeader(name: path, mode: 420, size: bytes.length),
          bytes,
        ),
      );
    }
    await controller.close();
  });

  return controller.stream.transform(tarWriter).transform(gzip.encoder);
}

/// Returns a [_FakeDb] and a set of [_CallLog] helpers for injection.
_Fakes _fakes({
  List<AssetDbModel> existing = const [],
  Set<String> existingFiles = const {},
}) => _Fakes(existing: existing, existingFiles: existingFiles);

class _Fakes {
  _Fakes({List<AssetDbModel> existing = const [], Set<String> existingFiles = const {}})
    : _existingById = {for (final a in existing) a.id: a},
      _existingFiles = {...existingFiles};

  final Map<int, AssetDbModel> _existingById;
  final Set<String> _existingFiles;
  final List<AssetDbModel> savedAssets = [];
  final Map<String, List<int>> writtenFiles = {};

  Future<AssetDbModel?> findAsset(int id) async => _existingById[id];
  bool fileExists(String path) => _existingFiles.contains(path);
  Future<void> writeFile(String path, Stream<List<int>> bytesStream) async {
    writtenFiles[path] = await bytesStream.fold<List<int>>([], (buf, chunk) => buf..addAll(chunk));
  }

  Future<void> saveAsset(AssetDbModel asset) async => savedAssets.add(asset);

  String storagePathFor(AssetType type, int id, String ext) => type.getStoragePath(id: id, extension: ext);
  String relativePathFor(AssetType type, int id, String ext) => type.getRelativeStoragePath(id: id, extension: ext);
}

Future<ImportMediaResult> _run(
  _Fakes fakes,
  Stream<List<int>> tarGzStream,
) => ImportMediaFromTarService.call(
  tarGzStream: tarGzStream,
  findAsset: fakes.findAsset,
  fileExists: fakes.fileExists,
  writeFile: fakes.writeFile,
  saveAsset: fakes.saveAsset,
  getStoragePath: fakes.storagePathFor,
  getRelativePath: fakes.relativePathFor,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory testSupportDir;

  setUpAll(() async {
    testSupportDir = await Directory.systemTemp.createTemp('storypad_asset_import_test_');
    kSupportDirectory = testSupportDir;
  });

  tearDownAll(() async {
    if (await testSupportDir.exists()) {
      await testSupportDir.delete(recursive: true);
    }
  });

  group('ImportMediaFromTarService', () {
    // --- type inference ---

    group('type inference', () {
      test('infers image type from images/ subdirectory prefix', () async {
        const id = 1714986140000;
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('images/$id.jpg', [1, 2, 3]),
        ]);

        await _run(fakes, stream);

        expect(fakes.savedAssets.single.type, AssetType.image);
      });

      test('infers audio type from audio/ subdirectory prefix', () async {
        const id = 1714986140001;
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('audio/$id.m4a', [1, 2, 3]),
        ]);

        await _run(fakes, stream);

        expect(fakes.savedAssets.single.type, AssetType.audio);
      });

      test('infers image type for root-level jpg', () async {
        const id = 1714986140002;
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('$id.jpg', [1, 2, 3]),
        ]);

        await _run(fakes, stream);

        expect(fakes.savedAssets.single.type, AssetType.image);
      });

      test('infers audio type for root-level m4a', () async {
        const id = 1714986140003;
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('$id.m4a', [1, 2, 3]),
        ]);

        await _run(fakes, stream);

        expect(fakes.savedAssets.single.type, AssetType.audio);
      });

      for (final ext in ['.mp3', '.aac', '.wav', '.ogg', '.flac']) {
        test('infers audio for root-level $ext', () async {
          const id = 1714986140004;
          final fakes = _fakes();
          final stream = _buildTarGz([
            ('$id$ext', [1]),
          ]);
          await _run(fakes, stream);
          expect(fakes.savedAssets.single.type, AssetType.audio);
        });
      }
    });

    // --- new import ---

    group('new entry (no existing record, no existing file)', () {
      test('writes file and creates DB record', () async {
        const id = 1714986140010;
        final bytes = [10, 20, 30];
        final storagePath = AssetType.image.getStoragePath(id: id, extension: '.jpg');
        final fakes = _fakes();
        final stream = _buildTarGz([('images/$id.jpg', bytes)]);

        final result = await _run(fakes, stream);

        expect(result.imported, 1);
        expect(result.skipped, 0);
        expect(fakes.writtenFiles[storagePath], bytes);
        expect(fakes.savedAssets.single.id, id);
        expect(fakes.savedAssets.single.createdAt, DateTime.fromMillisecondsSinceEpoch(id));
      });

      test('counts multiple new entries correctly', () async {
        const id1 = 1714986140011;
        const id2 = 1714986140012;
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('images/$id1.jpg', [1]),
          ('images/$id2.png', [2]),
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 2);
        expect(result.skipped, 0);
        expect(fakes.savedAssets.length, 2);
      });
    });

    // --- restore (record exists, file missing) ---

    group('restore (existing record, missing file)', () {
      test('writes file but does NOT create a new DB record', () async {
        const id = 1714986140020;
        final existingAsset = AssetDbModel.fromLocalPath(
          id: id,
          localPath: 'images/$id.jpg',
          type: AssetType.image,
        );
        final storagePath = existingAsset.localFilePath;
        final fakes = _fakes(existing: [existingAsset]);
        final stream = _buildTarGz([
          ('images/$id.jpg', [99]),
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 1);
        expect(result.skipped, 0);
        expect(fakes.writtenFiles[storagePath], [99]);
        expect(fakes.savedAssets, isEmpty); // existing record kept
      });

      test('restores to the existing asset path when archive metadata differs', () async {
        const id = 1714986140021;
        final existingAsset = AssetDbModel.fromLocalPath(
          id: id,
          localPath: 'audio/$id.m4a',
          type: AssetType.audio,
        );
        final storagePath = existingAsset.localFilePath;
        final fakes = _fakes(existing: [existingAsset]);
        final stream = _buildTarGz([
          ('images/$id.jpg', [7, 8, 9]),
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 1);
        expect(result.skipped, 0);
        expect(fakes.writtenFiles[storagePath], [7, 8, 9]);
        expect(
          fakes.writtenFiles[AssetType.image.getStoragePath(id: id, extension: '.jpg')],
          isNull,
        );
        expect(fakes.savedAssets, isEmpty);
      });
    });

    // --- skip ---

    group('skip (existing record AND file already on disk)', () {
      test('skips entry and writes nothing', () async {
        const id = 1714986140030;
        final existingAsset = AssetDbModel.fromLocalPath(
          id: id,
          localPath: 'images/$id.jpg',
          type: AssetType.image,
        );
        final storagePath = existingAsset.localFilePath;
        final fakes = _fakes(
          existing: [existingAsset],
          existingFiles: {storagePath},
        );
        final stream = _buildTarGz([
          ('images/$id.jpg', [1]),
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 0);
        expect(result.skipped, 1);
        expect(fakes.writtenFiles, isEmpty);
        expect(fakes.savedAssets, isEmpty);
      });
    });

    // --- invalid entries ---

    group('invalid entries', () {
      test('skips entry with no extension', () async {
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('images/noextension', [1]),
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 0);
        expect(result.skipped, 0);
        expect(fakes.savedAssets, isEmpty);
      });

      test('skips entry whose stem is not a numeric timestamp', () async {
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('images/photo.jpg', [1]),
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 0);
        expect(result.skipped, 0);
        expect(fakes.savedAssets, isEmpty);
      });

      test('skips valid entries mixed with invalid ones', () async {
        const validId = 1714986140040;
        final fakes = _fakes();
        final stream = _buildTarGz([
          ('images/photo.jpg', [1]), // invalid — non-numeric name
          ('images/$validId.jpg', [2]), // valid
          ('images/noextension', [3]), // invalid — no extension
        ]);

        final result = await _run(fakes, stream);

        expect(result.imported, 1);
        expect(result.skipped, 0);
      });
    });

    // --- real file integration (optional) ---

    group('real .tar.gz file', () {
      const realFilePath = 'examples/backups/StoryPad-iPhone-assets-2026-05-08T01:47:47.635256.tar.gz';

      test('parses real StoryPad export without throwing', () async {
        final file = File(realFilePath);
        if (!file.existsSync()) {
          markTestSkipped('Real archive not found at $realFilePath — skipping');
          return;
        }

        final fakes = _fakes();
        final result = await _run(fakes, file.openRead());

        // Should produce at least one imported file and no errors.
        expect(result.imported + result.skipped, greaterThan(0));
      });
    });
  });
}
