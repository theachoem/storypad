import 'dart:io';
import 'package:storypad/core/types/support_directory_path.dart';

class StorageInfoService {
  /// Returns size in bytes for each [SupportDirectoryPath].
  /// Directories that don't exist yet return 0.
  Future<Map<SupportDirectoryPath, int>> computeLocalSizes() async {
    final Map<SupportDirectoryPath, int> result = {};

    for (final path in SupportDirectoryPath.values) {
      result[path] = await _directorySize(path.directory);
    }

    return result;
  }

  /// Deletes all files inside [path]'s directory without removing the directory itself.
  Future<void> clearDirectory(SupportDirectoryPath path) async {
    final dir = path.directory;
    if (!await dir.exists()) return;

    await for (final entity in dir.list(recursive: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<int> _directorySize(Directory dir) async {
    if (!await dir.exists()) return 0;

    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }
}
