import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/device_info_object.dart';

void main() {
  group('BackupObject Tests', () {
    final testDateTime = DateTime.now();
    final testDeviceInfo = DeviceInfoObject('Test Model', 'Test ID');
    final testFileInfo = BackupFileObject(
      createdAt: testDateTime,
      device: testDeviceInfo,
    );
    final testTables = {
      'users': [
        {'id': 1, 'name': 'John Doe'}
      ],
      'entries': [
        {'id': 101, 'title': 'My First Entry'}
      ],
    };

    test('Constructor should create an object with correct properties', () {
      final backupObject = BackupObject(
        tables: testTables,
        fileInfo: testFileInfo,
        version: 2,
        deletedRecords: {},
      );

      expect(backupObject.version, 2);
      expect(backupObject.tables, testTables);
      expect(backupObject.fileInfo, testFileInfo);
    });

    test('Constructor should use currentVersion as default version', () {
      final backupObject = BackupObject(
        tables: testTables,
        fileInfo: testFileInfo,
        deletedRecords: {},
      );

      expect(backupObject.version, BackupObject.currentVersion);
    });

    test('toContents() should serialize the object to a valid map', () {
      final backupObject = BackupObject(
        tables: testTables,
        fileInfo: testFileInfo,
        version: 1,
        deletedRecords: {},
      );

      final contents = backupObject.toContents();

      final expectedMap = {
        'version': 1,
        'tables': testTables,
        'meta_data': {
          'device_model': 'Test Model',
          'device_id': 'Test ID',
          'created_at': testDateTime.toIso8601String(),
        }
      };
      expect(contents, equals(expectedMap));
    });

    test('fromContents() should deserialize a map to a valid BackupObject', () {
      // ARRANGE
      final contentMap = {
        'version': 1,
        'tables': testTables,
        'meta_data': {
          'device_model': 'Test Model',
          'device_id': 'Test ID',
          'created_at': testDateTime.toIso8601String(),
        }
      };

      final backupObject = BackupObject.fromContents(contentMap);

      expect(backupObject.version, 1);
      expect(backupObject.tables, testTables);
      expect(backupObject.fileInfo.device.model, 'Test Model');
      expect(backupObject.fileInfo.device.id, 'Test ID');

      expect(
        backupObject.fileInfo.createdAt.toIso8601String(),
        testDateTime.toIso8601String(),
      );
    });

    test('fromContents() should use currentVersion if version is missing or invalid in map', () {
      final contentMapWithNullVersion = {
        'version': null,
        'tables': testTables,
        'meta_data': {
          'device_model': 'Test Model',
          'device_id': 'Test ID',
          'created_at': testDateTime.toIso8601String(),
        }
      };

      final contentMapWithInvalidVersion = {
        'version': 'not-a-number',
        'tables': testTables,
        'meta_data': {
          'device_model': 'Test Model',
          'device_id': 'Test ID',
          'created_at': testDateTime.toIso8601String(),
        }
      };

      final backupObject1 = BackupObject.fromContents(contentMapWithNullVersion);
      final backupObject2 = BackupObject.fromContents(contentMapWithInvalidVersion);

      expect(backupObject1.version, BackupObject.currentVersion);
      expect(backupObject2.version, BackupObject.currentVersion);
    });
  });
}
