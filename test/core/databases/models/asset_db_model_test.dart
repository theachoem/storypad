import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
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

  group('AssetDbModel.matchingCloudDestinationFor', () {
    test('is null when the asset has no destinations at all', () {
      final asset = buildAsset(cloudDestinations: {});
      final nextcloud = _FakeCloudService(currentUser: _FakeUser());

      expect(asset.matchingCloudDestinationFor([nextcloud]), isNull);
    });

    test('is null when no signed-in service matches the destination\'s serviceType', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/1.jpg', 'file_name': '1.jpg'},
          },
        },
      );
      final drive = _FakeCloudService(currentUser: _FakeUser(), serviceType: BackupServiceType.google_drive);

      expect(asset.matchingCloudDestinationFor([drive]), isNull);
    });

    test('is null when the destination belongs to a different (switched) account on the same service', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'old-admin@example.com/StoryPad': {'file_id': '/StoryPad/images/1.jpg', 'file_name': '1.jpg'},
          },
        },
      );
      final nextcloud = _FakeCloudService(currentUser: _FakeUser(identifier: 'new-admin@example.com/StoryPad'));

      expect(asset.matchingCloudDestinationFor([nextcloud]), isNull);
    });

    test('finds the destination matching the currently signed-in account', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/1.jpg', 'file_name': '1.jpg'},
          },
        },
      );
      final nextcloud = _FakeCloudService(currentUser: _FakeUser(identifier: 'admin@example.com/StoryPad'));

      final destination = asset.matchingCloudDestinationFor([nextcloud]);

      expect(destination?.serviceType, BackupServiceType.nextcloud);
      expect(destination?.identifier, 'admin@example.com/StoryPad');
      expect(destination?.fileId, '/StoryPad/images/1.jpg');
    });
  });
}

class _FakeUser implements CloudServiceUser {
  _FakeUser({this.identifier = 'admin@example.com/StoryPad'});

  @override
  final BackupServiceType serviceType = BackupServiceType.nextcloud;

  @override
  final String identifier;

  @override
  String get destinationKey => identifier;

  @override
  List<({String label, String value})> get configuration => const [];

  @override
  String? get displayName => 'Tester';

  @override
  String? get photoUrl => null;

  @override
  bool? get autoBackupEnabled => true;

  @override
  String? get globalId => 'global-id';
}

class _FakeCloudService implements BackupCloudService {
  _FakeCloudService({
    required this.currentUser,
    this.serviceType = BackupServiceType.nextcloud,
  });

  @override
  final CloudServiceUser? currentUser;

  @override
  final BackupServiceType serviceType;

  @override
  bool get isSignedIn => currentUser != null;

  @override
  bool get autoBackupEnabled => true;

  @override
  bool get hasCompression => true;

  @override
  Future<List<int>?> downloadFileBytes(String fileId) async => null;

  @override
  Future<CloudFileObject?> uploadFile(String fileName, io.File file, {String? folderName}) async => null;

  @override
  Future<CloudStorageQuotaObject?> fetchStorageQuota() async => null;

  @override
  Future<List<CloudFileObject>> listFilesInFolder(String folderName) async => [];

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async => {};

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
