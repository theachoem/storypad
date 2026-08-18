import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/types/support_directory_path.dart';

/// Disk cache for rendered map marker bitmaps.
///
/// Drawing one marker means decoding a photo, painting a canvas and encoding a
/// PNG, and a map can show a hundred of them. The result is deterministic for
/// a given (appearance, pixel ratio), so it is worth keeping: re-reading a
/// ~15KB PNG costs ~1ms against ~300ms to redraw. That is what makes the map
/// fast on the *first* view after a restart, not just on a re-pan — an
/// in-memory cache alone can never do that.
///
/// Caching strategy:
/// - Keyed by marker appearance ([SpMapMarker.iconCacheKey]) + pixel ratio +
///   [designVersion]. Nothing here is keyed by story or marker id, so pins
///   that look alike (every text-only pin of the same weekday colour) share
///   one entry.
/// - Concurrent requests for the same key are deduplicated, so a burst of
///   identical placeholder markers renders once.
/// - Pruned oldest-modified-first down to [_maxEntries], once per app run.
class MapMarkerBitmapCache {
  MapMarkerBitmapCache._();

  static final MapMarkerBitmapCache instance = MapMarkerBitmapCache._();

  /// Bump whenever the marker drawing changes, otherwise cached PNGs would
  /// pin the old look forever.
  static const int designVersion = 1;

  static const int _maxEntries = 500;

  final Map<String, Future<Uint8List>> _inFlightByFileName = {};
  bool _pruneScheduled = false;

  /// Returns the cached PNG bytes for [cacheKey], calling [render] only when
  /// this appearance has never been drawn at this [pixelRatio].
  ///
  /// [render] reports whether its result is worth keeping: a marker that fell
  /// back to a placeholder because its photo wouldn't decode must not be
  /// written under the photo's key, or one bad decode pins the placeholder
  /// there for good.
  Future<Uint8List> resolve({
    required String cacheKey,
    required double pixelRatio,
    required Future<({Uint8List bytes, bool cacheable})> Function() render,
  }) {
    final String fileName = _fileNameFor(cacheKey, pixelRatio);

    final Future<Uint8List>? inFlight = _inFlightByFileName[fileName];
    if (inFlight != null) return inFlight;

    final Future<Uint8List> future = _resolveInternal(fileName: fileName, render: render);
    _inFlightByFileName[fileName] = future;

    return future.whenComplete(() => _inFlightByFileName.remove(fileName));
  }

  Future<Uint8List> _resolveInternal({
    required String fileName,
    required Future<({Uint8List bytes, bool cacheable})> Function() render,
  }) async {
    final File file = File('${SupportDirectoryPath.map_markers.directoryPath}/$fileName');

    try {
      if (file.existsSync()) return await file.readAsBytes();
    } catch (e) {
      AppLogger.d('$runtimeType#resolve failed to read $fileName: $e');
    }

    final ({Uint8List bytes, bool cacheable}) rendered = await render();
    if (rendered.cacheable) unawaited(_write(file, rendered.bytes));

    return rendered.bytes;
  }

  Future<void> _write(File file, Uint8List bytes) async {
    try {
      await SupportDirectoryPath.map_markers.ensureDirectoryExists();

      // Temp file + rename, so being killed mid-write can't leave a truncated
      // PNG behind that every later run would happily serve as a cache hit.
      final File temp = File('${file.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);

      unawaited(_pruneOnce());
    } catch (e) {
      AppLogger.d('$runtimeType#_write failed for ${file.path}: $e');
    }
  }

  Future<void> _pruneOnce() async {
    if (_pruneScheduled) return;
    _pruneScheduled = true;

    try {
      final List<File> files = SupportDirectoryPath.map_markers.directory.listSync().whereType<File>().toList();
      if (files.length <= _maxEntries) return;

      files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      for (final File file in files.take(files.length - _maxEntries)) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.d('$runtimeType#_pruneOnce failed: $e');
    }
  }

  String _fileNameFor(String cacheKey, double pixelRatio) {
    final String safeKey = cacheKey.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safeKey}_${pixelRatio.toStringAsFixed(2)}_v$designVersion.png';
  }
}
