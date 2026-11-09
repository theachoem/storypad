import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
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

  group('NextcloudCloudService.describeError', () {
    // The server is the user's own; none of these may survive into an exception message
    // (those reach Crashlytics logs).
    const String host = 'cloud.example.com';
    final RequestOptions request = RequestOptions(path: 'https://$host/remote.php/dav/files/me/StoryPad');

    void expectNoServer(String description) {
      expect(description, isNot(contains(host)));
      expect(description, isNot(contains('192.168.1.20')));
      expect(description, isNot(contains('remote.php')));
    }

    test('a failed DNS lookup keeps only the error kinds and errno', () {
      final error = DioException.connectionError(
        requestOptions: request,
        reason: "Failed host lookup: '$host'",
        error: const SocketException(
          "Failed host lookup: '$host'",
          osError: OSError('nodename nor servname provided, or not known', 8),
        ),
      );

      // Proves the raw text would have leaked, so the test can't pass vacuously.
      expect(error.toString(), contains(host));

      final description = NextcloudCloudService.describeError(error);
      expect(description, 'DioException(connectionError, SocketException(errno 8))');
      expectNoServer(description);
    });

    test('a refused connection drops the address and port', () {
      final error = SocketException(
        'Connection refused',
        address: InternetAddress('192.168.1.20'),
        port: 443,
        osError: const OSError('Connection refused', 61),
      );

      final description = NextcloudCloudService.describeError(error);
      expect(description, 'SocketException(errno 61)');
      expectNoServer(description);
    });

    test('a bad response keeps the status code', () {
      final error = DioException.badResponse(
        statusCode: 502,
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 502, statusMessage: 'Bad Gateway from $host'),
      );

      final description = NextcloudCloudService.describeError(error);
      expect(description, 'DioException(badResponse, status 502)');
      expectNoServer(description);
    });

    test('anything else is reduced to its type', () {
      expect(NextcloudCloudService.describeError(TimeoutException('timed out talking to $host')), 'TimeoutException');
      expect(
        NextcloudCloudService.describeError(const HandshakeException('bad certificate for $host')),
        'HandshakeException',
      );
      expect(NextcloudCloudService.describeError(null), 'Null');
    });
  });
}
