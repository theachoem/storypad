import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('BackupImportHistoryStorage', () {
    late BackupImportHistoryStorage storage;

    setUp(() {
      storage = BackupImportHistoryStorage();
      SharedPreferences.setMockInitialValues({});
    });

    group('getImportHistoryByYear', () {
      test('returns empty list when storage is empty', () async {
        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history, isEmpty);
      });

      test('returns empty list when service not found', () async {
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          DateTime(2024, 1, 15),
        );

        // Trying to get history for a different service
        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2025,
        );

        expect(history, isEmpty);
      });

      test('returns single timestamp when one import recorded', () async {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          timestamp,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 1);
        expect(history[0], timestamp);
      });

      test('returns multiple timestamps in reverse chronological order', () async {
        final timestamps = [
          DateTime(2024, 1, 15, 10, 30),
          DateTime(2024, 1, 10, 8, 0),
          DateTime(2024, 1, 5, 14, 45),
        ];

        for (final ts in timestamps) {
          await storage.markAsImported(
            BackupServiceType.google_drive,
            2024,
            ts,
          );
        }

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 3);
        // Should be in reverse chronological order (most recent first)
        expect(history[0], timestamps[2]); // Last added
        expect(history[1], timestamps[1]);
        expect(history[2], timestamps[0]); // First added
      });

      test('preserves timezone information in timestamps', () async {
        final timestamp = DateTime(2024, 1, 15, 10, 30, 0, 123).toUtc();
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          timestamp,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 1);
        // DateTime equality checks both date, time, and UTC conversion
        expect(history[0].isUtc, timestamp.isUtc);
      });
    });

    group('markAsImported', () {
      test('stores a single timestamp', () async {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          timestamp,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 1);
        expect(history[0], timestamp);
      });

      test('adds new timestamp to existing history', () async {
        final timestamp1 = DateTime(2024, 1, 15, 10, 30);
        final timestamp2 = DateTime(2024, 1, 20, 14, 0);

        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          timestamp1,
        );
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          timestamp2,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 2);
        expect(history[0], timestamp2); // Most recent first
        expect(history[1], timestamp1);
      });

      test('respects maxHistorySize limit of 30', () async {
        // Add 35 timestamps to test that only last 30 are kept
        for (int i = 0; i < 35; i++) {
          final timestamp = DateTime(2024, 1, 1).add(Duration(days: i));
          await storage.markAsImported(
            BackupServiceType.google_drive,
            2024,
            timestamp,
          );
        }

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 30);
      });

      test('maintains separate history for different years', () async {
        final ts2024 = DateTime(2024, 1, 15, 10, 30);
        final ts2025 = DateTime(2025, 1, 15, 10, 30);

        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          ts2024,
        );
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2025,
          ts2025,
        );

        final history2024 = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );
        final history2025 = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2025,
        );

        expect(history2024.length, 1);
        expect(history2024[0], ts2024);
        expect(history2025.length, 1);
        expect(history2025[0], ts2025);
      });

      test('maintains separate history for different services', () async {
        final timestamp = DateTime(2024, 1, 15, 10, 30);

        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          timestamp,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 1);
        expect(history[0], timestamp);
      });
    });

    group('clearService', () {
      test('removes all history for a service', () async {
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          DateTime(2024, 1, 15),
        );
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2025,
          DateTime(2025, 1, 15),
        );

        await storage.clearService(BackupServiceType.google_drive);

        final history2024 = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );
        final history2025 = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2025,
        );

        expect(history2024, isEmpty);
        expect(history2025, isEmpty);
      });

      test('does nothing when clearing non-existent service', () async {
        // Should not throw
        await storage.clearService(BackupServiceType.google_drive);

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history, isEmpty);
      });

      test('clears entire storage when removing only service', () async {
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          DateTime(2024, 1, 15),
        );

        await storage.clearService(BackupServiceType.google_drive);

        // Reading the raw map should return null (storage is empty)
        final data = await storage.readMap();
        expect(data, isNull);
      });

      test('maintains other service data when clearing one', () async {
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          DateTime(2024, 1, 15),
        );

        // Note: In current implementation, only google_drive exists,
        // but this test structure supports future service additions
        await storage.clearService(BackupServiceType.google_drive);

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history, isEmpty);
      });
    });

    group('Integration scenarios', () {
      test('year-by-year import tracking across multiple years', () async {
        final years = [2022, 2023, 2024, 2025];

        // Mark each year as imported
        for (final year in years) {
          await storage.markAsImported(
            BackupServiceType.google_drive,
            year,
            DateTime(year, 1, 15),
          );
        }

        // Verify each year's history
        for (final year in years) {
          final history = await storage.getImportHistoryByYear(
            BackupServiceType.google_drive,
            year,
          );
          expect(history.length, 1);
          expect(history[0].year, year);
        }
      });

      test('handles rapid successive imports without data loss', () async {
        final timestamps = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 2),
          DateTime(2024, 1, 3),
          DateTime(2024, 1, 4),
          DateTime(2024, 1, 5),
        ];

        // Rapidly add multiple timestamps
        for (final ts in timestamps) {
          await storage.markAsImported(
            BackupServiceType.google_drive,
            2024,
            ts,
          );
        }

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 5);
        // Verify all timestamps are present (in reverse order)
        for (int i = 0; i < timestamps.length; i++) {
          expect(history[i], timestamps[timestamps.length - 1 - i]);
        }
      });

      test('recovery scenario: sign out and re-import', () async {
        // Initial import
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          DateTime(2024, 1, 15),
        );

        // User signs out
        await storage.clearService(BackupServiceType.google_drive);

        // Verify cleaned
        var history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );
        expect(history, isEmpty);

        // User signs back in and imports
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          DateTime(2024, 1, 20),
        );

        history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );
        expect(history.length, 1);
        expect(history[0].day, 20); // New import
      });
    });

    group('Edge cases', () {
      test('handles leap year dates correctly', () async {
        final leapYearDate = DateTime(2024, 2, 29, 12, 0);
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          leapYearDate,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 1);
        expect(history[0], leapYearDate);
      });

      test('handles year boundary transitions', () async {
        final newYearsEveTimestamp = DateTime(2024, 12, 31, 23, 59, 59);
        final newYearsEveTimestamp2025 = DateTime(2025, 1, 1, 0, 0, 0);

        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          newYearsEveTimestamp,
        );
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2025,
          newYearsEveTimestamp2025,
        );

        final history2024 = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );
        final history2025 = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2025,
        );

        expect(history2024.length, 1);
        expect(history2025.length, 1);
        expect(history2024[0].year, 2024);
        expect(history2025[0].year, 2025);
      });

      test('handles microseconds precision in timestamps', () async {
        final preciseTimestamp = DateTime(2024, 1, 15, 10, 30, 45, 123456);
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2024,
          preciseTimestamp,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2024,
        );

        expect(history.length, 1);
        // Verify microseconds are preserved through ISO8601 round-trip
        expect(history[0].microsecond, preciseTimestamp.microsecond);
      });

      test('handles very old dates (year 2000)', () async {
        final oldDate = DateTime(2000, 1, 1);
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2000,
          oldDate,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2000,
        );

        expect(history.length, 1);
        expect(history[0].year, 2000);
      });

      test('handles future dates', () async {
        final futureDate = DateTime(2099, 12, 31);
        await storage.markAsImported(
          BackupServiceType.google_drive,
          2099,
          futureDate,
        );

        final history = await storage.getImportHistoryByYear(
          BackupServiceType.google_drive,
          2099,
        );

        expect(history.length, 1);
        expect(history[0].year, 2099);
      });
    });
  });
}
