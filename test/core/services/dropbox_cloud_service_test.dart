import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/dropbox_cloud_service.dart';

void main() {
  group('DropboxCloudService', () {
    late DropboxCloudService service;

    setUp(() {
      service = DropboxCloudService();
    });

    test('serviceType is dropbox', () {
      expect(service.serviceType, BackupServiceType.dropbox);
    });

    test('hasCompression is true (shared with every provider)', () {
      expect(service.hasCompression, isTrue);
    });

    test('is not signed in before initialize/signIn', () {
      expect(service.isSignedIn, isFalse);
      expect(service.currentUser, isNull);
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
        service.deleteFile('id:whatever'),
        throwsA(
          isA<AuthException>().having((e) => e.type, 'type', AuthExceptionType.signInRequired),
        ),
      );
    });
  });
}
