import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/device_info_object.dart';
import 'package:storypad/core/objects/yearly_backup_files_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_latest_checker_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_messenger.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_uploader_service.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';

/// Backups v4: new apps write v4 files (pages may be Markdown); apps before them never see those; v3 files are read
/// once for years without a v4 file, and never written.
void main() {
  CloudFileObject file(String id, String version, int year, int ms, {String model = 'iPhone'}) => CloudFileObject(
    fileName: 'Backup__${version}__${year}__${ms}__${model}__device-$model.zip',
    id: id,
    description: null,
  );

  group('file names', () {
    test('yearly files are written as v4', () {
      final info = BackupFileObject(
        createdAt: DateTime.fromMillisecondsSinceEpoch(1734350000000),
        device: DeviceInfoObject(model: 'iPhone 15 Pro', id: 'abc'),
        hasCompression: true,
        year: 2025,
      );
      expect(info.version, '4');
      expect(info.fileNameWithExtention, 'Backup__4__2025__1734350000000__iPhone 15 Pro__abc.zip');
    });

    test('v4 and v3 names parse; the Drive query of apps before v4 never matches a v4 name', () {
      final v4 = BackupFileObject.fromFileName('Backup__4__2025__1734350000000__iPhone 15 Pro__abc.zip')!;
      expect((v4.version, v4.year, v4.device.model), ('4', 2025, 'iPhone 15 Pro'));
      expect(v4.createdAt, DateTime.fromMillisecondsSinceEpoch(1734350000000));

      final v3 = BackupFileObject.fromFileName('Backup__3__2025__1734350000000__iPhone 15 Pro__abc.zip')!;
      expect(v3.version, '3');

      // Old apps: `name contains 'Backup__3__' or name contains 'Backup::3::'` on Drive; elsewhere the v3 parser.
      expect(v4.fileName.contains('Backup__3__') || v4.fileName.contains('Backup::3::'), isFalse);
    });

    test('an unknown (newer) version is ignored, as apps before v4 ignore v4', () {
      expect(BackupFileObject.fromFileName('Backup__5__2025__1734350000000__iPhone__abc.zip'), isNull);
      expect(file('x', '5', 2025, 1).year, isNull);
    });
  });

  group('backup contents', () {
    BackupObject backup() => BackupObject(
      tables: {'stories': []},
      year: 2025,
      fileInfo: BackupFileObject(
        createdAt: DateTime(2025),
        device: DeviceInfoObject(model: 'iPhone', id: 'abc'),
        hasCompression: false,
        year: 2025,
      ),
    );

    test('are written under `data`, so apps before v4 reject the file instead of restoring empty pages', () {
      final contents = backup().toContents();
      expect(contents['version'], 2);
      expect(contents.containsKey('tables'), isFalse);
      expect(contents['data'], {'stories': []});
    });

    test('both keys read back', () {
      final contents = jsonDecode(jsonEncode(backup().toContents())) as Map<String, dynamic>;
      expect(BackupObject.fromContents(contents).tables, {'stories': []});

      final legacy = {...contents}
        ..remove('data')
        ..['tables'] = {'stories': []}
        ..['version'] = 1;
      expect(BackupObject.fromContents(legacy).tables, {'stories': []});
    });
  });

  group('YearlyBackupFilesObject', () {
    test('splits current and legacy files, newest per year, ignoring other versions', () {
      final files = YearlyBackupFilesObject.fromFiles([
        file('a', '4', 2025, 200),
        file('b', '4', 2025, 100),
        file('c', '3', 2025, 300),
        file('d', '3', 2024, 50),
        file('e', '5', 2023, 10),
        CloudFileObject(fileName: 'notes.txt', id: 'f', description: null),
      ]);
      expect(files.current.map((year, file) => MapEntry(year, file.id)), {2025: 'a'});
      expect(files.legacy.map((year, file) => MapEntry(year, file.id)), {2025: 'c', 2024: 'd'});
      expect(files.legacyOnly.keys, [2024]);
      expect(files.merged.map((year, file) => MapEntry(year, file.id)), {2025: 'a', 2024: 'd'});
    });
  });

  group('BackupLatestCheckerService', () {
    String contentsFor(int year, int ms) => jsonEncode(
      BackupObject(
        tables: {},
        year: year,
        fileInfo: BackupFileObject(
          createdAt: DateTime.fromMillisecondsSinceEpoch(ms),
          device: DeviceInfoObject(model: 'iPhone', id: 'abc'),
          hasCompression: false,
          year: year,
        ),
      ).toContents(),
    );

    Future<BackupLatestCheckerResponse> check(YearlyBackupFilesObject files, {Map<int, DateTime?>? local}) {
      final service = _FakeCloudService(files, contentsFor: contentsFor);
      return BackupLatestCheckerService(
        messenger: BackupSyncMessenger(),
      ).start(service, _EmptyImportHistory(), local ?? {2024: DateTime(2024), 2025: DateTime(2025)});
    }

    test('only current files are the synced state; legacy files are imported for years without one', () async {
      final response = await check(
        YearlyBackupFilesObject(
          current: {2025: file('v4-2025', '4', 2025, 2000)},
          legacy: {2025: file('v3-2025', '3', 2025, 1000), 2024: file('v3-2024', '3', 2024, 900)},
        ),
      );
      expect(response.backupCloudFileByYear!.map((year, file) => MapEntry(year, file.id)), {2025: 'v4-2025'});
      expect(response.lastSyncedAtByYear!.keys, [2025]);
      expect(response.backupContentsByYear!.keys, unorderedEquals([2024, 2025]));
      expect(response.olderAppDeviceModels, isEmpty);
    });

    test('a service with only legacy files still has content to import, and nothing synced', () async {
      final response = await check(YearlyBackupFilesObject(legacy: {2024: file('v3-2024', '3', 2024, 900)}));
      expect(response.backupCloudFileByYear, isEmpty);
      expect(response.backupContentsByYear!.keys, [2024]);
    });

    test('a legacy file newer than the current one means an older app is still writing', () async {
      final response = await check(
        YearlyBackupFilesObject(
          current: {2025: file('v4-2025', '4', 2025, 1000)},
          legacy: {2025: file('v3-2025', '3', 2025, 2000, model: 'iPad')},
        ),
      );
      expect(response.olderAppDeviceModels, {'iPad'});
      expect(response.backupContentsByYear!.keys, [2025], reason: 'the legacy file itself is not imported');
    });
  });

  group('BackupUploaderService', () {
    test('a year another device just gave its first v4 file is left for the next sync (import first)', () async {
      final service = _FakeCloudService(
        YearlyBackupFilesObject(current: {2025: file('v4-2025', '4', 2025, 5000)}),
        contentsFor: (year, ms) => '',
      );
      final response = await BackupUploaderService(messenger: BackupSyncMessenger()).startStep4(
        service,
        _EmptyImportHistory(),
        {},
        {2025: DateTime.fromMillisecondsSinceEpoch(6000)},
        {}, // No v4 file for 2025 when this sync checked.
      );
      expect(response.hasError, isFalse);
      expect(response.uploadedYearlyFiles, isEmpty);
    });
  });
}

class _EmptyImportHistory extends BackupImportHistoryStorage {
  @override
  Future<List<DateTime>> getImportHistoryByYear(BackupServiceType serviceType, int year) async => [];
}

class _FakeCloudService implements BackupCloudService {
  _FakeCloudService(this.files, {required this.contentsFor});

  final YearlyBackupFilesObject files;
  final String Function(int year, int ms) contentsFor;

  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  @override
  bool get isSignedIn => true;

  @override
  CloudServiceUser? get currentUser => null;

  @override
  Future<YearlyBackupFilesObject> fetchYearlyBackups() async => files;

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    final info = file.getFileInfo()!;
    final contents = contentsFor(info.year!, info.createdAt.millisecondsSinceEpoch);
    return (contents, contents.length);
  }

  @override
  Future<CloudFileObject?> uploadFile(String fileName, io.File file, {String? folderName}) async => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
