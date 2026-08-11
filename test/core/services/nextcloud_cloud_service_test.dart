import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/nextcloud_cloud_service.dart';

void main() {
  group('NextcloudCloudService', () {
    late NextcloudCloudService service;

    setUp(() {
      service = NextcloudCloudService();
    });

    test('serviceType is nextcloud', () {
      expect(service.serviceType, BackupServiceType.nextcloud);
    });

    test('hasCompression is true (shared with every provider)', () {
      expect(service.hasCompression, isTrue);
    });

    test('is not signed in before initialize/connect', () {
      expect(service.isSignedIn, isFalse);
      expect(service.currentUser, isNull);
    });

    test('generic signIn() is a no-op that reports the current state', () async {
      expect(await service.signIn(), isFalse);
    });

    test('canAccessRequestedScopes/requestScope are false when signed out', () async {
      expect(await service.canAccessRequestedScopes(), isFalse);
      expect(await service.requestScope(), isFalse);
    });

    test('reauthenticateIfNeeded throws signInRequired when never connected', () async {
      await expectLater(
        service.reauthenticateIfNeeded(),
        throwsA(
          isA<AuthException>().having((e) => e.type, 'type', AuthExceptionType.signInRequired),
        ),
      );
    });

    test('file operations throw signInRequired when not connected', () async {
      await expectLater(
        service.deleteFile('/StoryPad/backups/whatever.zip'),
        throwsA(
          isA<AuthException>().having((e) => e.type, 'type', AuthExceptionType.signInRequired),
        ),
      );
    });
  });

  // Pure over its input (no network/DB), so it's testable directly — the
  // one thing standing between a user-typed folder name and a WebDAV path.
  group('NextcloudCloudService.sanitizeFolderName', () {
    test('returns null for null input (use the default)', () {
      expect(NextcloudCloudService.sanitizeFolderName(null), isNull);
    });

    test('returns null for blank/whitespace-only input', () {
      expect(NextcloudCloudService.sanitizeFolderName(''), isNull);
      expect(NextcloudCloudService.sanitizeFolderName('   '), isNull);
    });

    test('trims surrounding whitespace and slashes', () {
      expect(NextcloudCloudService.sanitizeFolderName('  myjournal  '), 'myjournal');
      expect(NextcloudCloudService.sanitizeFolderName('/myjournal/'), 'myjournal');
    });

    test('preserves a nested relative path', () {
      expect(NextcloudCloudService.sanitizeFolderName('Journals/MyDiary'), 'Journals/MyDiary');
    });

    test('collapses repeated/empty segments', () {
      expect(NextcloudCloudService.sanitizeFolderName('Journals//MyDiary'), 'Journals/MyDiary');
    });

    test('drops "." and ".." segments defensively', () {
      expect(NextcloudCloudService.sanitizeFolderName('../etc/myjournal'), 'etc/myjournal');
      expect(NextcloudCloudService.sanitizeFolderName('./myjournal'), 'myjournal');
      expect(NextcloudCloudService.sanitizeFolderName('..'), isNull);
    });
  });
}
