import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/asset_type.dart';

void main() {
  AssetDbModel buildAsset({required Map<String, Map<String, Map<String, String>>> cloudDestinations}) {
    final now = DateTime(2026, 1, 1);
    return AssetDbModel(
      id: 1,
      originalSource: 'images/1.jpg',
      cloudDestinations: cloudDestinations,
      createdAt: now,
      updatedAt: now,
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
      type: AssetType.image,
      tags: null,
    );
  }

  group('AssetDbModel.uploadedServiceTypes', () {
    test('is empty when never uploaded anywhere', () {
      final asset = buildAsset(cloudDestinations: {});
      expect(asset.uploadedServiceTypes, isEmpty);
    });

    test('lists every service with at least one destination', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.google_drive.id: {
            'tester@example.com': {'file_id': 'abc', 'file_name': '1.jpg'},
          },
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/1.jpg', 'file_name': '1.jpg'},
          },
        },
      );

      expect(
        asset.uploadedServiceTypes,
        unorderedEquals([BackupServiceType.google_drive, BackupServiceType.nextcloud]),
      );
    });

    test('excludes a service whose entry map is empty', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.google_drive.id: {},
        },
      );

      expect(asset.uploadedServiceTypes, isEmpty);
    });
  });

  group('AssetDbModel.allCloudDestinations', () {
    test('is empty when never uploaded anywhere', () {
      final asset = buildAsset(cloudDestinations: {});
      expect(asset.allCloudDestinations, isEmpty);
    });

    test('flattens every service+identifier into one list', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.google_drive.id: {
            'tester@example.com': {'file_id': 'abc', 'file_name': '1.jpg'},
          },
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/1.jpg', 'file_name': '1.jpg'},
          },
        },
      );

      expect(asset.allCloudDestinations, hasLength(2));
      expect(
        asset.allCloudDestinations,
        containsAll([
          (serviceType: BackupServiceType.google_drive, identifier: 'tester@example.com', fileId: 'abc'),
          (
            serviceType: BackupServiceType.nextcloud,
            identifier: 'admin@example.com/StoryPad',
            fileId: '/StoryPad/images/1.jpg',
          ),
        ]),
      );
    });

    test('includes multiple identifiers under the same service', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/1.jpg', 'file_name': '1.jpg'},
            'admin@example.com/OldFolder': {'file_id': '/OldFolder/images/1.jpg', 'file_name': '1.jpg'},
          },
        },
      );

      expect(asset.allCloudDestinations, hasLength(2));
    });

    test('skips an entry with no file_id', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.google_drive.id: {
            'tester@example.com': {'file_name': '1.jpg'},
          },
        },
      );

      expect(asset.allCloudDestinations, isEmpty);
    });
  });
}
