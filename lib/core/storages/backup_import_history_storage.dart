import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/storages/base_object_storages/map_storage.dart';

/// Stores the import/upload history per service per year
/// Tracks the last 30 imported/uploaded timestamps to detect if a remote backup file needs downloading
///
/// Structure:
/// {
///   "google_drive": {
///     "2024": ["2024-01-15T10:30:00.000Z", "2024-01-10T08:00:00.000Z", ...],
///     "2025": ["2025-01-15T10:30:00.000Z"]
///   },
///   "dropbox": {
///     "2024": ["2024-01-02T14:00:00.000Z"]
///   }
/// }
class BackupImportHistoryStorage extends MapStorage {
  static const int maxHistorySize = 30;

  /// Get import/upload history (last 30 timestamps) for a specific year and service
  Future<List<DateTime>> getImportHistoryByYear(
    BackupServiceType serviceType,
    int year,
  ) async {
    final data = await readMap();
    if (data == null) return [];

    final serviceData = data[serviceType.name] as Map<String, dynamic>?;
    if (serviceData == null) return [];

    final yearHistory = serviceData[year.toString()] as List<dynamic>?;
    if (yearHistory == null) return [];

    return yearHistory.whereType<String>().map((ts) => DateTime.tryParse(ts)).whereType<DateTime>().toList();
  }

  Future<void> markAsImported(
    BackupServiceType serviceType,
    int year,
    DateTime timestamp,
  ) async {
    final data = await readMap() ?? {};

    final serviceData = (data[serviceType.name] as Map<String, dynamic>?) ?? {};
    final yearHistory = (serviceData[year.toString()] as List<dynamic>?) ?? [];

    final timestampString = timestamp.toIso8601String();
    final existingHistory = yearHistory.whereType<String>().toList();

    // Skip if timestamp already exists
    if (existingHistory.contains(timestampString)) {
      return;
    }

    // Add new timestamp at the beginning (most recent first)
    final updatedHistory = <String>[
      timestampString,
      ...existingHistory.take(maxHistorySize - 1),
    ];

    serviceData[year.toString()] = updatedHistory;
    data[serviceType.name] = serviceData;

    await writeMap(data);
  }

  /// Clear import history for a specific service (e.g., on sign out)
  Future<void> clearService(BackupServiceType serviceType) async {
    final data = await readMap();
    if (data == null) return;

    data.remove(serviceType.name);
    if (data.isEmpty) {
      await write(null);
    } else {
      await writeMap(data);
    }
  }
}
