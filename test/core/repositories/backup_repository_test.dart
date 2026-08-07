import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/objects/nextcloud_user_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/nextcloud_cloud_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_images_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_importer_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_latest_checker_service.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_messenger.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_uploader_service.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/storages/backup_import_history_storage.dart';
import 'package:storypad/core/types/backup_connection_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BackupRepository buildRepository({
    required BackupCloudService googleDriveService,
    required NextcloudCloudService nextcloudService,
    bool hasInternet = true,
  }) {
    final messenger = BackupSyncMessenger();
    return BackupRepository(
      restoreService: RestoreBackupService(),
      messenger: messenger,
      step1ImagesUploader: BackupImagesUploaderService(messenger: messenger),
      step2LatestBackupChecker: BackupLatestCheckerService(messenger: messenger),
      step3LatestBackupImporter: BackupImporterService(messenger: messenger),
      step4NewBackupUploader: BackupUploaderService(messenger: messenger),
      internetChecker: _FakeInternetChecker(hasInternet),
      googleDriveService: googleDriveService,
      nextcloudService: nextcloudService,
      importHistoryStorage: BackupImportHistoryStorage(),
    );
  }

  group('BackupRepository.checkConnection', () {
    // The actual regression: previously checkConnection() returned on the
    // FIRST service that threw, so a broken Nextcloud connection meant
    // Google Drive's own status was never even checked.
    test('one service throwing does not prevent checking the other', () async {
      final repository = buildRepository(
        googleDriveService: _FakeCloudService(serviceType: BackupServiceType.google_drive, shouldThrow: false),
        nextcloudService: _FakeNextcloudService(shouldThrow: true),
      );

      final result = await repository.checkConnection();

      expect(result.isSuccess, isTrue);
      expect(result.data!.hasInternet, isTrue);
      expect(result.data!.statusByService[BackupServiceType.google_drive], BackupConnectionStatus.readyToSync);
      expect(result.data!.statusByService[BackupServiceType.nextcloud], BackupConnectionStatus.needServicePermission);
    });

    test('both services healthy report readyToSync for both', () async {
      final repository = buildRepository(
        googleDriveService: _FakeCloudService(serviceType: BackupServiceType.google_drive, shouldThrow: false),
        nextcloudService: _FakeNextcloudService(shouldThrow: false),
      );

      final result = await repository.checkConnection();

      expect(result.data!.statusByService[BackupServiceType.google_drive], BackupConnectionStatus.readyToSync);
      expect(result.data!.statusByService[BackupServiceType.nextcloud], BackupConnectionStatus.readyToSync);
    });

    test('no internet marks every signed-in service noInternet without checking them', () async {
      final repository = buildRepository(
        googleDriveService: _FakeCloudService(serviceType: BackupServiceType.google_drive, shouldThrow: false),
        nextcloudService: _FakeNextcloudService(shouldThrow: false),
        hasInternet: false,
      );

      final result = await repository.checkConnection();

      expect(result.data!.hasInternet, isFalse);
      expect(result.data!.statusByService[BackupServiceType.google_drive], BackupConnectionStatus.noInternet);
      expect(result.data!.statusByService[BackupServiceType.nextcloud], BackupConnectionStatus.noInternet);
    });

    test('nobody signed in at all fails fast', () async {
      final repository = buildRepository(
        googleDriveService: _FakeCloudService(serviceType: BackupServiceType.google_drive, signedIn: false),
        nextcloudService: _FakeNextcloudService(shouldThrow: false, signedIn: false),
      );

      final result = await repository.checkConnection();

      expect(result.isSuccess, isFalse);
    });

    test('a service that is not signed in is excluded from the result, the other still checked', () async {
      final repository = buildRepository(
        googleDriveService: _FakeCloudService(serviceType: BackupServiceType.google_drive, signedIn: false),
        nextcloudService: _FakeNextcloudService(shouldThrow: false),
      );

      final result = await repository.checkConnection();

      expect(result.isSuccess, isTrue);
      expect(result.data!.statusByService.containsKey(BackupServiceType.google_drive), isFalse);
      expect(result.data!.statusByService[BackupServiceType.nextcloud], BackupConnectionStatus.readyToSync);
    });
  });
}

class _FakeInternetChecker extends InternetCheckerService {
  _FakeInternetChecker(this._result);
  final bool _result;

  @override
  Future<bool> check() async => _result;
}

class _FakeNextcloudUser implements NextcloudUserObject {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  BackupServiceType get serviceType => BackupServiceType.nextcloud;

  @override
  String get identifier => 'tester@nextcloud.example.com';
}

class _FakeNextcloudService extends NextcloudCloudService {
  _FakeNextcloudService({required this.shouldThrow, this.signedIn = true});

  final bool shouldThrow;
  final bool signedIn;

  @override
  NextcloudUserObject? get currentUser => signedIn ? _FakeNextcloudUser() : null;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<bool> reauthenticateIfNeeded() async {
    if (shouldThrow) {
      throw AuthException(
        'Nextcloud credentials no longer valid',
        AuthExceptionType.tokenRevoked,
        serviceType: serviceType,
      );
    }
    return true;
  }

  @override
  Future<bool> canAccessRequestedScopes() async => true;
}

class _FakeCloudService implements BackupCloudService {
  _FakeCloudService({
    required this.serviceType,
    this.shouldThrow = false,
    this.signedIn = true,
  });

  @override
  final BackupServiceType serviceType;

  final bool shouldThrow;
  final bool signedIn;

  @override
  CloudServiceUser? get currentUser => signedIn ? _FakeUser(serviceType) : null;

  @override
  bool get isSignedIn => signedIn;

  @override
  bool get autoBackupEnabled => true;

  @override
  bool get hasCompression => true;

  @override
  Future<bool> reauthenticateIfNeeded() async {
    if (shouldThrow) {
      throw AuthException('Broken', AuthExceptionType.tokenRevoked, serviceType: serviceType);
    }
    return true;
  }

  @override
  Future<bool> canAccessRequestedScopes() async => true;

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

class _FakeUser implements CloudServiceUser {
  _FakeUser(this.serviceType);

  @override
  final BackupServiceType serviceType;

  @override
  String get identifier => 'tester@example.com';

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
