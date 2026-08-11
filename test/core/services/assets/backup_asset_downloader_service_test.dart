import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/assets/backup_asset_downloader_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/asset_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late io.Directory tempDir;
  late BackupAssetDownloaderService service;

  AssetDbModel buildAsset({required Map<String, Map<String, Map<String, String>>> cloudDestinations}) {
    final now = DateTime(2026, 1, 1);
    return AssetDbModel(
      id: 42,
      originalSource: 'images/42.jpg',
      cloudDestinations: cloudDestinations,
      createdAt: now,
      updatedAt: now,
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
      type: AssetType.image,
      tags: null,
    );
  }

  // asset.localFilePath resolves under kSupportDirectory, which is normally
  // set during app init — point it at a scratch dir for this group only.
  setUpAll(() {
    tempDir = io.Directory.systemTemp.createTempSync('backup_asset_downloader_test_');
    kSupportDirectory = tempDir;
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    service = BackupAssetDownloaderService();
  });

  tearDown(() {
    final imagesDir = io.Directory('${tempDir.path}/images');
    if (imagesDir.existsSync()) imagesDir.deleteSync(recursive: true);
  });

  group('BackupAssetDownloaderService', () {
    test('returns the local path immediately if the file already exists, without touching any service', () async {
      final asset = buildAsset(cloudDestinations: {});
      final file = io.File(asset.localFilePath);
      await file.create(recursive: true);
      await file.writeAsBytes([9, 9, 9]);

      final throwing = _FakeCloudService(
        currentUser: _FakeUser(),
        downloadShouldThrow: true,
      );

      final path = await service.downloadAsset(asset: asset, signedInServices: [throwing]);

      expect(path, asset.localFilePath);
      expect(io.File(path).readAsBytesSync(), [9, 9, 9]);
    });

    test('throws when the asset has no cloud destinations at all', () async {
      final asset = buildAsset(cloudDestinations: {});

      await expectLater(
        service.downloadAsset(
          asset: asset,
          signedInServices: [_FakeCloudService(currentUser: _FakeUser())],
        ),
        throwsA(isA<BackupAssetDownloadException>()),
      );
    });

    test('throws when no signed-in service matches the destination\'s serviceType', () async {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/42.jpg', 'file_name': '42.jpg'},
          },
        },
      );

      // Only Drive is signed in — the asset's only destination is Nextcloud.
      final drive = _FakeCloudService(currentUser: _FakeUser(), serviceType: BackupServiceType.google_drive);

      await expectLater(
        service.downloadAsset(asset: asset, signedInServices: [drive]),
        throwsA(isA<BackupAssetDownloadException>()),
      );
    });

    test('throws when the destination belongs to a different (switched) account on the same service', () async {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'old-admin@example.com/StoryPad': {'file_id': '/StoryPad/images/42.jpg', 'file_name': '42.jpg'},
          },
        },
      );

      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(identifier: 'new-admin@example.com/StoryPad'),
        serviceType: BackupServiceType.nextcloud,
      );

      await expectLater(
        service.downloadAsset(asset: asset, signedInServices: [nextcloud]),
        throwsA(isA<BackupAssetDownloadException>()),
      );
    });

    test('downloads from the one matching signed-in service and writes the file', () async {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/42.jpg', 'file_name': '42.jpg'},
          },
        },
      );

      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(identifier: 'admin@example.com/StoryPad'),
        serviceType: BackupServiceType.nextcloud,
        bytesToDownload: [1, 2, 3],
      );

      final path = await service.downloadAsset(asset: asset, signedInServices: [nextcloud]);

      expect(path, asset.localFilePath);
      expect(io.File(path).readAsBytesSync(), [1, 2, 3]);
    });

    test('picks the correct destination when both Drive and Nextcloud have this asset, only one signed in', () async {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.google_drive.id: {
            'tester@example.com': {'file_id': 'drive-id', 'file_name': '42.jpg'},
          },
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/42.jpg', 'file_name': '42.jpg'},
          },
        },
      );

      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(identifier: 'admin@example.com/StoryPad'),
        serviceType: BackupServiceType.nextcloud,
        bytesToDownload: [4, 5, 6],
      );

      final path = await service.downloadAsset(asset: asset, signedInServices: [nextcloud]);

      expect(io.File(path).readAsBytesSync(), [4, 5, 6]);
    });

    test('throws when the matched service returns null bytes', () async {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/42.jpg', 'file_name': '42.jpg'},
          },
        },
      );

      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(identifier: 'admin@example.com/StoryPad'),
        serviceType: BackupServiceType.nextcloud,
        bytesToDownload: null,
      );

      await expectLater(
        service.downloadAsset(asset: asset, signedInServices: [nextcloud]),
        throwsA(isA<BackupAssetDownloadException>()),
      );
    });

    test('lets the underlying service exception propagate unwrapped', () async {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'admin@example.com/StoryPad': {'file_id': '/StoryPad/images/42.jpg', 'file_name': '42.jpg'},
          },
        },
      );

      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(identifier: 'admin@example.com/StoryPad'),
        serviceType: BackupServiceType.nextcloud,
        downloadShouldThrow: true,
      );

      await expectLater(
        service.downloadAsset(asset: asset, signedInServices: [nextcloud]),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _FakeUser implements CloudServiceUser {
  _FakeUser({
    this.identifier = 'admin@example.com/StoryPad',
  });

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
    this.bytesToDownload,
    this.downloadShouldThrow = false,
  });

  @override
  final CloudServiceUser? currentUser;

  final List<int>? bytesToDownload;
  final bool downloadShouldThrow;

  @override
  Future<List<int>?> downloadFileBytes(String fileId) async {
    if (downloadShouldThrow) throw Exception('network error');
    return bytesToDownload;
  }

  @override
  final BackupServiceType serviceType;

  @override
  bool get isSignedIn => currentUser != null;

  @override
  bool get autoBackupEnabled => true;

  @override
  bool get hasCompression => true;

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
