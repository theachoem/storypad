import 'dart:io';
import 'dart:async';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path;
import 'package:storypad/core/types/asset_type.dart';
import 'package:tar/tar.dart';

enum ImportMediaEntryResult {
  skipped,
  importedNew,
  importedRestored,
}

typedef ImportMediaResult = ({int imported, int skipped});

/// A previewable archive entry discovered during [scan].
class ImportMediaScanEntry {
  const ImportMediaScanEntry({
    required this.id,
    required this.type,
    required this.ext,
    required this.entryName,
    required this.previewFile,
  });

  final int id;
  final AssetType type;
  final String ext;
  final String entryName;
  final File previewFile;
}

/// Scans or imports `.tar.gz` media archives using the filename stem as the
/// asset ID and timestamp.
class ImportMediaFromTarService {
  // Audio file extensions used when the archive entry is at the root level and
  // there is no subdirectory prefix to derive the type from.
  static const _audioExtensions = {'.m4a', '.mp3', '.aac', '.wav', '.ogg', '.flac'};

  /// Writes preview copies to [tempDir] without touching final asset storage.
  static Future<List<ImportMediaScanEntry>> scan({
    required Stream<List<int>> tarGzStream,
    required Directory tempDir,
  }) async {
    final reader = TarReader(tarGzStream.transform(gzip.decoder));
    final entries = <ImportMediaScanEntry>[];

    await tempDir.create(recursive: true);

    while (await reader.moveNext()) {
      final entry = reader.current;
      if (entry.type != TypeFlag.reg) continue;

      final entryName = entry.name;
      final basename = path.basename(entryName);
      final ext = path.extension(basename);
      // Keep scan preview consistent with import behavior: extension-less
      // files are not importable and should not appear in review.
      if (ext.isEmpty) continue;

      final stem = path.basenameWithoutExtension(basename);
      final id = int.tryParse(stem);
      if (id == null) continue;
      final createdAt = _createdAtFromId(id);
      if (createdAt == null) continue;

      final type = _inferType(entryName, ext);
      final previewFile = File('${tempDir.path}/$stem$ext');
      final previewSink = previewFile.openWrite();
      try {
        await previewSink.addStream(entry.contents);
      } finally {
        await previewSink.close();
      }

      entries.add(
        ImportMediaScanEntry(
          id: id,
          type: type,
          ext: ext,
          entryName: entryName,
          previewFile: previewFile,
        ),
      );
    }

    return entries;
  }

  /// Imports each valid archive entry into asset storage.
  static Future<ImportMediaResult> call({
    required Stream<List<int>> tarGzStream,
    required Future<AssetDbModel?> Function(int id) findAsset,
    required bool Function(String path) fileExists,
    required Future<void> Function(String path, Stream<List<int>> bytesStream) writeFile,
    required Future<void> Function(AssetDbModel asset) saveAsset,
    required String Function(AssetType type, int id, String ext) getStoragePath,
    required String Function(AssetType type, int id, String ext) getRelativePath,
  }) async {
    int imported = 0;
    int skipped = 0;

    final reader = TarReader(tarGzStream.transform(gzip.decoder));

    while (await reader.moveNext()) {
      final entry = reader.current;

      // Only process regular files; skip directories, symlinks, etc.
      if (entry.type != TypeFlag.reg) continue;

      final result = await _processEntry(
        entry: entry,
        findAsset: findAsset,
        fileExists: fileExists,
        writeFile: writeFile,
        saveAsset: saveAsset,
        getStoragePath: getStoragePath,
        getRelativePath: getRelativePath,
      );

      // Count outcomes explicitly so skipped entries do not affect imported
      // totals and null results remain ignored.
      if (result == ImportMediaEntryResult.skipped) {
        skipped++;
      } else if (result == ImportMediaEntryResult.importedNew || result == ImportMediaEntryResult.importedRestored) {
        imported++;
      }
    }

    return (imported: imported, skipped: skipped);
  }

  static Future<ImportMediaEntryResult?> _processEntry({
    required TarEntry entry,
    required Future<AssetDbModel?> Function(int id) findAsset,
    required bool Function(String path) fileExists,
    required Future<void> Function(String path, Stream<List<int>> bytesStream) writeFile,
    required Future<void> Function(AssetDbModel asset) saveAsset,
    required String Function(AssetType type, int id, String ext) getStoragePath,
    required String Function(AssetType type, int id, String ext) getRelativePath,
  }) async {
    // Archive filenames use the millisecond timestamp stem as the asset ID.
    final entryName = entry.name;
    final fileName = entryName.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) return null; // no extension — skip

    final stem = fileName.substring(0, dotIndex);
    final ext = fileName.substring(dotIndex); // includes the leading dot

    final id = int.tryParse(stem);
    if (id == null) return null; // filename is not a numeric timestamp — skip

    final createdAt = _createdAtFromId(id);
    if (createdAt == null) return null;

    final existing = await findAsset(id);
    final assetType = _inferType(entryName, ext);
    final storagePath = existing?.localFilePath ?? getStoragePath(assetType, id, ext);

    if (existing != null && fileExists(storagePath)) {
      return ImportMediaEntryResult.skipped;
    }

    await writeFile(storagePath, entry.contents);

    if (existing == null) {
      final asset = AssetDbModel.fromLocalPath(
        id: id,
        localPath: getRelativePath(assetType, id, ext),
        type: assetType,
        createdAt: createdAt,
      );
      await saveAsset(asset);
      return ImportMediaEntryResult.importedNew;
    }

    // existing != null but file was missing — file restored, record kept as-is
    return ImportMediaEntryResult.importedRestored;
  }

  /// Determines the [AssetType] for a tar entry.
  ///
  /// Priority:
  /// 1. Subdirectory prefix (`images/` → image, `audio/` → audio).
  /// 2. File extension for root-level entries.
  static AssetType _inferType(String entryName, String ext) {
    if (entryName.startsWith('audio/')) return AssetType.audio;
    if (entryName.startsWith('images/')) return AssetType.image;
    return _audioExtensions.contains(ext.toLowerCase()) ? AssetType.audio : AssetType.image;
  }

  static DateTime? _createdAtFromId(int id) {
    final now = DateTime.now();
    final plausibleLowerBound = DateTime(2000).millisecondsSinceEpoch;
    final plausibleUpperBound = now.add(const Duration(days: 365)).millisecondsSinceEpoch;
    if (id < plausibleLowerBound || id > plausibleUpperBound) return null;

    return DateTime.fromMillisecondsSinceEpoch(id);
  }
}
