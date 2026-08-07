import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_messenger.dart';
import 'package:storypad/core/types/asset_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackupSyncMessenger messenger;
  late BackupImagesUploaderService service;
  late _FakeCloudService cloudService;

  setUp(() {
    messenger = BackupSyncMessenger();
    service = BackupImagesUploaderService(messenger: messenger);
    cloudService = _FakeCloudService(currentUser: _FakeUser());
  });

  tearDown(() => messenger.dispose());

  group('BackupImagesUploaderService - uploadAssets gate', () {
    // Deferring media must never look like a failure: BackupRepository#sync
    // aborts the whole run when step 1 fails, which would stop entries — the
    // data that costs almost no bandwidth — from backing up at all.
    test('reports success when uploads are deferred', () async {
      final result = await service.start(cloudService, uploadAssets: false);

      expect(result, isTrue);
    });

    test('uploads nothing when deferred', () async {
      await service.start(cloudService, uploadAssets: false);

      expect(cloudService.uploadedFileNames, isEmpty);
    });

    // The DB is unavailable in this unit test, so pendingAssets throws — which
    // is exactly the point: a cosmetic count must not fail the step.
    test('still succeeds when the pending count cannot be read', () async {
      final messages = <BackupSyncMessage>[];
      messenger.messages.listen(messages.add);

      final result = await service.start(cloudService, uploadAssets: false);
      await Future.delayed(Duration.zero);

      expect(result, isTrue);
      expect(messages.last.success, isTrue);
      expect(messages.last.processing, isFalse);
    });

    test('throws when the service is not signed in, regardless of the gate', () async {
      final signedOut = _FakeCloudService(currentUser: null);

      expect(
        () => service.start(signedOut, uploadAssets: false),
        throwsA(anything),
      );
    });
  });

  group('BackupImagesUploaderService - pendingAssets', () {
    test('is empty when no user is signed in', () async {
      final signedOut = _FakeCloudService(currentUser: null);

      expect(await service.pendingAssets(signedOut), isEmpty);
    });
  });

  // findBackfillSource is the core decision logic behind "an asset never
  // downloaded to this device shouldn't be invisible to a newly-connected
  // service" — pure over its inputs (no DB/network), so it's testable
  // directly without the DB-unavailable limitation above.
  group('BackupImagesUploaderService - findBackfillSource', () {
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

    test('finds another signed-in service that already has the asset', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'nextcloud-tester@example.com': {'file_id': 'abc', 'file_name': '1.jpg'},
          },
        },
      );
      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(serviceType: BackupServiceType.nextcloud, identifier: 'nextcloud-tester@example.com'),
        serviceType: BackupServiceType.nextcloud,
      );

      final source = service.findBackfillSource(asset, [cloudService, nextcloud], cloudService);

      expect(source, same(nextcloud));
    });

    test('returns null when no other connected service has the asset', () {
      final asset = buildAsset(cloudDestinations: {});

      final source = service.findBackfillSource(asset, [cloudService], cloudService);

      expect(source, isNull);
    });

    test('excludes the target service itself even if it has a matching entry', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.google_drive.id: {
            'tester@example.com': {'file_id': 'abc', 'file_name': '1.jpg'},
          },
        },
      );

      final source = service.findBackfillSource(asset, [cloudService], cloudService);

      expect(source, isNull);
    });

    test('skips a candidate service that is not signed in', () {
      final asset = buildAsset(
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'nextcloud-tester@example.com': {'file_id': 'abc', 'file_name': '1.jpg'},
          },
        },
      );
      final signedOutNextcloud = _FakeCloudService(currentUser: null, serviceType: BackupServiceType.nextcloud);

      final source = service.findBackfillSource(asset, [cloudService, signedOutNextcloud], cloudService);

      expect(source, isNull);
    });
  });

  group('BackupImagesUploaderService - backfillFromOtherService', () {
    late io.Directory tempDir;

    AssetDbModel buildBackfillableAsset() {
      final now = DateTime(2026, 1, 1);
      return AssetDbModel(
        id: 42,
        originalSource: 'images/42.jpg',
        cloudDestinations: {
          BackupServiceType.nextcloud.id: {
            'nextcloud-tester@example.com': {'file_id': 'remote-id', 'file_name': '42.jpg'},
          },
        },
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
      tempDir = io.Directory.systemTemp.createTempSync('backup_images_uploader_test_');
      kSupportDirectory = tempDir;
    });

    tearDownAll(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    tearDown(() {
      // Undo whatever a test left in the images/ subdirectory so the next
      // test starts clean (kSupportDirectory itself can't be reassigned).
      final imagesDir = io.Directory('${tempDir.path}/images');
      if (imagesDir.existsSync()) {
        imagesDir.deleteSync(recursive: true);
      } else {
        final imagesAsFile = io.File('${tempDir.path}/images');
        if (imagesAsFile.existsSync()) imagesAsFile.deleteSync();
      }
    });

    test('downloads bytes from the source service and writes them locally', () async {
      final asset = buildBackfillableAsset();
      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(serviceType: BackupServiceType.nextcloud, identifier: 'nextcloud-tester@example.com'),
        serviceType: BackupServiceType.nextcloud,
        bytesToDownload: [1, 2, 3],
      );

      final result = await service.backfillFromOtherService(asset, [cloudService, nextcloud], cloudService);

      expect(result, BackfillOutcome.succeeded);
      expect(io.File(asset.localFilePath).readAsBytesSync(), [1, 2, 3]);
    });

    test('skips, writes nothing, when the download fails transiently', () async {
      final asset = buildBackfillableAsset();
      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(serviceType: BackupServiceType.nextcloud, identifier: 'nextcloud-tester@example.com'),
        serviceType: BackupServiceType.nextcloud,
        downloadShouldThrow: true,
      );

      final result = await service.backfillFromOtherService(asset, [cloudService, nextcloud], cloudService);

      expect(result, BackfillOutcome.skipped);
      expect(io.File(asset.localFilePath).existsSync(), isFalse);
    });

    test('reports sourceMissing and clears the stale cloudDestinations entry on a 404', () async {
      final asset = buildBackfillableAsset();
      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(serviceType: BackupServiceType.nextcloud, identifier: 'nextcloud-tester@example.com'),
        serviceType: BackupServiceType.nextcloud,
        downloadNotFound: true,
      );

      final result = await service.backfillFromOtherService(asset, [cloudService, nextcloud], cloudService);

      expect(result, BackfillOutcome.sourceMissing);
      expect(io.File(asset.localFilePath).existsSync(), isFalse);
    });

    // Deterministically forces the *write* (not the download) to fail: with
    // "images" already occupied by a plain file, creating the real target
    // file underneath it is impossible — same FileSystemException shape as
    // running out of disk space, which is exactly the code path being
    // exercised here (this code treats any write-time FileSystemException as
    // storage-full, rather than parsing OS-specific error codes).
    test('throws a localStorageFull ServiceException when the write fails', () async {
      io.File('${tempDir.path}/images').createSync(recursive: true);

      final asset = buildBackfillableAsset();
      final nextcloud = _FakeCloudService(
        currentUser: _FakeUser(serviceType: BackupServiceType.nextcloud, identifier: 'nextcloud-tester@example.com'),
        serviceType: BackupServiceType.nextcloud,
        bytesToDownload: [1, 2, 3],
      );

      await expectLater(
        service.backfillFromOtherService(asset, [cloudService, nextcloud], cloudService),
        throwsA(isA<ServiceException>().having((e) => e.type, 'type', ServiceExceptionType.localStorageFull)),
      );
    });
  });
}

class _FakeUser implements CloudServiceUser {
  _FakeUser({
    this.serviceType = BackupServiceType.google_drive,
    this.identifier = 'tester@example.com',
  });

  @override
  final BackupServiceType serviceType;

  @override
  final String identifier;

  @override
  String get destinationKey => identifier;

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
    this.serviceType = BackupServiceType.google_drive,
    this.bytesToDownload,
    this.downloadShouldThrow = false,
    this.downloadNotFound = false,
  });

  @override
  final CloudServiceUser? currentUser;

  final List<int>? bytesToDownload;
  final bool downloadShouldThrow;
  final bool downloadNotFound;

  @override
  Future<List<int>?> downloadFileBytes(String fileId) async {
    if (downloadNotFound) {
      throw FileOperationException(
        'File not found during downloadFileBytes',
        FileOperationType.download,
        serviceType: serviceType,
        statusCode: 404,
      );
    }
    if (downloadShouldThrow) throw Exception('network error');
    return bytesToDownload;
  }

  @override
  final BackupServiceType serviceType;

  final List<String> uploadedFileNames = [];

  @override
  bool get isSignedIn => currentUser != null;

  @override
  bool get autoBackupEnabled => true;

  @override
  bool get hasCompression => true;

  @override
  Future<CloudFileObject?> uploadFile(String fileName, io.File file, {String? folderName}) async {
    uploadedFileNames.add(fileName);
    return null;
  }

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
