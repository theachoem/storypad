import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/yearly_backup_files_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/cloud_optimize/older_app_asset_ids_service.dart';

void main() {
  String contents(List<Map<String, dynamic>> assets) => jsonEncode({
    'version': 1,
    'tables': {'assets': assets, 'stories': []},
  });

  CloudFileObject legacy(String id, int year) => CloudFileObject(
    fileName: 'Backup__3__${year}__1000__iPad__device-iPad.zip',
    id: id,
    description: null,
  );

  test('lists the live assets of a backup, not the deleted ones', () {
    final ids = OlderAppAssetIdsService.liveAssetIdsIn(
      contents([
        {'id': 1},
        {'id': 2, 'permanently_deleted_at': '2025-01-01T00:00:00.000'},
        {'id': 3},
      ]),
      'assets',
    );
    expect(ids, {1, 3});
  });

  test("reads every legacy file of the service, and none of the current ones", () async {
    final service = _FakeCloudService(
      YearlyBackupFilesObject(
        current: {2025: CloudFileObject(fileName: 'Backup__4__2025__9000__iPhone__x.zip', id: 'v4', description: null)},
        legacy: {2025: legacy('v3-2025', 2025), 2024: legacy('v3-2024', 2024)},
      ),
      {
        'v3-2025': contents([
          {'id': 10},
        ]),
        'v3-2024': contents([
          {'id': 20},
        ]),
        'v4': contents([
          {'id': 30},
        ]),
      },
    );
    expect(await OlderAppAssetIdsService.fetch(service), {10, 20});
  });

  test('unknown when a legacy file cannot be read', () async {
    final service = _FakeCloudService(
      YearlyBackupFilesObject(legacy: {2025: legacy('v3-2025', 2025), 2024: legacy('v3-2024', 2024)}),
      {
        'v3-2025': contents([
          {'id': 10},
        ]),
        'v3-2024': 'not json',
      },
    );
    expect(await OlderAppAssetIdsService.fetch(service), isNull);
  });

  test('none to keep without legacy files', () async {
    final service = _FakeCloudService(const YearlyBackupFilesObject(), {});
    expect(await OlderAppAssetIdsService.fetch(service), isEmpty);
  });
}

class _FakeCloudService implements BackupCloudService {
  _FakeCloudService(this.files, this.contentsById);

  final YearlyBackupFilesObject files;
  final Map<String, String> contentsById;

  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  @override
  Future<YearlyBackupFilesObject> fetchYearlyBackups() async => files;

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async {
    final contents = contentsById[file.id];
    return contents == null ? null : (contents, contents.length);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
