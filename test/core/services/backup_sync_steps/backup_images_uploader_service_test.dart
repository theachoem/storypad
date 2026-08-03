import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackupImagesUploaderService service;
  late _FakeCloudService cloudService;

  setUp(() {
    service = BackupImagesUploaderService();
    cloudService = _FakeCloudService(currentUser: _FakeUser());
  });

  tearDown(() => service.controller.close());

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
      final messages = <BackupSyncMessage?>[];
      service.message.listen(messages.add);

      final result = await service.start(cloudService, uploadAssets: false);
      await Future.delayed(Duration.zero);

      expect(result, isTrue);
      expect(messages.last?.success, isTrue);
      expect(messages.last?.processing, isFalse);
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
}

class _FakeUser implements CloudServiceUser {
  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  @override
  String get identifier => 'tester@example.com';

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
  _FakeCloudService({required this.currentUser});

  @override
  final CloudServiceUser? currentUser;

  final List<String> uploadedFileNames = [];

  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

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
