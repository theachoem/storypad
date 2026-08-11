import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/nextcloud_user_object.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

void main() {
  group('NextcloudUserObject', () {
    final user = NextcloudUserObject(
      serverUrl: 'https://cloud.example.com',
      username: 'thea',
      appPassword: 'app-password-token',
      autoBackupEnabled: true,
    );

    test('round-trips through JSON', () {
      final decoded = NextcloudUserObject.fromJson(user.toJson());

      expect(decoded.serverUrl, user.serverUrl);
      expect(decoded.username, user.username);
      expect(decoded.appPassword, user.appPassword);
      expect(decoded.displayName, user.displayName);
      expect(decoded.autoBackupEnabled, user.autoBackupEnabled);
    });

    test('serviceType is nextcloud', () {
      expect(user.serviceType, BackupServiceType.nextcloud);
    });

    test('identifier clips the server URL to host only, no scheme', () {
      expect(user.identifier, 'thea@cloud.example.com');
    });

    test('globalId is scoped by serviceType and identifier', () {
      expect(user.globalId, 'nextcloud_thea@cloud.example.com');
    });

    test('identifier keeps the port when the server URL has one', () {
      final withPort = NextcloudUserObject(
        serverUrl: 'http://192.168.1.5:8080',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(withPort.identifier, 'admin@192.168.1.5:8080');
      expect(withPort.globalId, isNull); // bare IP host, not globally unique
    });

    test('globalId is null for a localhost host, identifier still works', () {
      final local = NextcloudUserObject(
        serverUrl: 'http://localhost:8080',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(local.identifier, 'admin@localhost:8080');
      expect(local.globalId, isNull);
    });

    test('globalId is null for a bare IPv4 host without a port', () {
      final ip = NextcloudUserObject(
        serverUrl: 'https://127.0.0.1',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(ip.identifier, 'admin@127.0.0.1');
      expect(ip.globalId, isNull);
    });

    test('identifier includes a non-root deployment path', () {
      final pathed = NextcloudUserObject(
        serverUrl: 'https://example.com/cloud-a',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(pathed.identifier, 'admin@example.com/cloud-a');
    });

    test('identifier distinguishes two installs sharing a host under different paths', () {
      final cloudA = NextcloudUserObject(
        serverUrl: 'https://example.com/cloud-a',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );
      final cloudB = NextcloudUserObject(
        serverUrl: 'https://example.com/cloud-b',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(cloudA.identifier, isNot(cloudB.identifier));
    });

    test('identifier includes both port and path when both are present', () {
      final pathed = NextcloudUserObject(
        serverUrl: 'http://192.168.1.5:8080/cloud-a',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(pathed.identifier, 'admin@192.168.1.5:8080/cloud-a');
    });

    test('identifier strips leading/trailing slashes from the deployment path', () {
      final pathed = NextcloudUserObject(
        serverUrl: 'https://example.com/cloud-a/',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
      );

      expect(pathed.identifier, 'admin@example.com/cloud-a');
    });

    test('authHeaders sends HTTP Basic auth with username:appPassword', () {
      final headers = user.authHeaders;
      expect(headers['Authorization'], startsWith('Basic '));

      final decoded = utf8.decode(base64Decode(headers['Authorization']!.replaceFirst('Basic ', '')));
      expect(decoded, 'thea:app-password-token');
    });

    test('folderName defaults to null for accounts connected before it existed', () {
      expect(user.folderName, isNull);
    });

    test('folderName round-trips through JSON when set', () {
      final withFolder = NextcloudUserObject(
        serverUrl: 'https://cloud.example.com',
        username: 'thea',
        appPassword: 'app-password-token',
        autoBackupEnabled: true,
        folderName: 'Journals/MyDiary',
      );

      final decoded = NextcloudUserObject.fromJson(withFolder.toJson());

      expect(decoded.folderName, 'Journals/MyDiary');
    });

    test('destinationKey falls back to the default folder when folderName is null', () {
      expect(user.folderName, isNull);
      expect(user.destinationKey, '${user.identifier}/${NextcloudUserObject.defaultFolderName}');
    });

    test('destinationKey folds in an explicit folder name matching the default', () {
      final explicitDefault = NextcloudUserObject(
        serverUrl: 'https://cloud.example.com',
        username: 'thea',
        appPassword: 'app-password-token',
        autoBackupEnabled: true,
        folderName: NextcloudUserObject.defaultFolderName,
      );

      expect(explicitDefault.destinationKey, '${explicitDefault.identifier}/${NextcloudUserObject.defaultFolderName}');
    });

    test('destinationKey folds in a custom folder name, percent-encoding its own slashes', () {
      final customFolder = NextcloudUserObject(
        serverUrl: 'https://cloud.example.com',
        username: 'thea',
        appPassword: 'app-password-token',
        autoBackupEnabled: true,
        folderName: 'Journals/MyDiary',
      );

      expect(customFolder.destinationKey, '${customFolder.identifier}/Journals%2FMyDiary');
    });

    test('destinationKey is unambiguous when a deployment path and a nested folder could otherwise collide', () {
      // Without escaping, "example.com/cloud-a" + folder "StoryPad" and
      // "example.com" + folder "cloud-a/StoryPad" both naively join to
      // "example.com/cloud-a/StoryPad" — two genuinely different
      // installs/folders that must never be treated as the same destination.
      final deploymentPath = NextcloudUserObject(
        serverUrl: 'https://example.com/cloud-a',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
        folderName: 'StoryPad',
      );
      final nestedFolder = NextcloudUserObject(
        serverUrl: 'https://example.com',
        username: 'admin',
        appPassword: 'pw',
        autoBackupEnabled: true,
        folderName: 'cloud-a/StoryPad',
      );

      expect(deploymentPath.destinationKey, isNot(nestedFolder.destinationKey));
    });

    test('destinationKey differs between two accounts using different folders, '
        'same account otherwise', () {
      final folderA = NextcloudUserObject(
        serverUrl: 'https://cloud.example.com',
        username: 'thea',
        appPassword: 'app-password-token',
        autoBackupEnabled: true,
        folderName: 'FolderA',
      );
      final folderB = folderA.copyWith(folderName: 'FolderB');

      expect(folderA.identifier, folderB.identifier); // same account
      expect(folderA.destinationKey, isNot(folderB.destinationKey)); // different storage location
    });

    test('configuration shows the folder as a ~/-prefixed path — never the app password', () {
      final withFolder = NextcloudUserObject(
        serverUrl: 'https://cloud.example.com',
        username: 'thea',
        appPassword: 'super-secret-token',
        autoBackupEnabled: true,
        folderName: 'Journals/MyDiary',
      );

      expect(withFolder.configuration, hasLength(1));
      expect(withFolder.configuration.single.value, '~/Journals/MyDiary');
      expect(withFolder.configuration.any((e) => e.value.contains('super-secret-token')), isFalse);
    });

    test('configuration folder falls back to the default when folderName is null', () {
      expect(user.folderName, isNull);
      expect(user.configuration.single.value, '~/${NextcloudUserObject.defaultFolderName}');
    });
  });
}
