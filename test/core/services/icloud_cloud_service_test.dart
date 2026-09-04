import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/icloud_cloud_service.dart';
import 'package:storypad/core/storages/icloud_user_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nativeChannel = MethodChannel('default_platform_channel');
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // In-memory stand-in for the keychain — ICloudUserStorage's key is the
  // class's runtimeType ("ICloudUserObject"), but the mock responds
  // generically to whatever key it's given so it doesn't need to know that.
  late Map<String, String> secureStorageValues;

  /// Mocks the native iCloud method channel. [available] backs
  /// `isAvailable`; [accountId] (or [accountIdError]) backs `fetchAccountId`.
  void mockNative({required bool available, String? accountId, PlatformException? accountIdError}) {
    messenger.setMockMethodCallHandler(nativeChannel, (call) async {
      switch (call.method) {
        case 'ICloudBackupService.isAvailable':
          return available;
        case 'ICloudBackupService.fetchAccountId':
          if (accountIdError != null) throw accountIdError;
          return accountId;
        default:
          throw MissingPluginException();
      }
    });
  }

  setUp(() {
    secureStorageValues = {};
    messenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      final args = call.arguments as Map;
      final key = args['key'] as String;
      switch (call.method) {
        case 'read':
          return secureStorageValues[key];
        case 'write':
          secureStorageValues[key] = args['value'] as String;
          return null;
        case 'delete':
          secureStorageValues.remove(key);
          return null;
        default:
          throw MissingPluginException();
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(nativeChannel, null);
    messenger.setMockMethodCallHandler(secureStorageChannel, null);
  });

  group('ICloudCloudService', () {
    test('serviceType is icloud', () {
      expect(ICloudCloudService().serviceType, BackupServiceType.icloud);
    });

    test('fresh connect: native reports available + an accountId creates and persists a user', () async {
      mockNative(available: true, accountId: 'record-a');
      final service = ICloudCloudService();

      final signedIn = await service.signIn();

      expect(signedIn, isTrue);
      expect(service.isSignedIn, isTrue);
      expect(service.currentUser?.accountId, 'record-a');
      // Persisted, not just in-memory — a fresh ICloudCloudService reading
      // storage should see the same account.
      final reloaded = ICloudCloudService();
      await reloaded.initialize();
      expect(reloaded.currentUser?.accountId, 'record-a');
    });

    test('not available: currentUser is cleared, signIn reports false', () async {
      mockNative(available: false);
      final service = ICloudCloudService();

      final signedIn = await service.signIn();

      expect(signedIn, isFalse);
      expect(service.isSignedIn, isFalse);
      expect(service.currentUser, isNull);
    });

    test('transient network failure with a cached user keeps it and reports signed in', () async {
      mockNative(available: true, accountId: 'record-a');
      final service = ICloudCloudService();
      await service.signIn();

      mockNative(available: true, accountIdError: PlatformException(code: 'NETWORK'));
      final signedIn = await service.signIn();

      expect(signedIn, isTrue, reason: 'a network blip must not be treated as signed out');
      expect(service.currentUser?.accountId, 'record-a', reason: 'cached account must survive a transient failure');
    });

    test('transient network failure with no cached user reports not signed in, without wiping anything', () async {
      mockNative(available: true, accountIdError: PlatformException(code: 'NETWORK'));
      final service = ICloudCloudService();

      final signedIn = await service.signIn();

      expect(signedIn, isFalse);
      expect(service.currentUser, isNull);
    });

    test('reauthenticateIfNeeded throws NetworkException on a transient failure with no cached user', () async {
      mockNative(available: true, accountIdError: PlatformException(code: 'NETWORK'));
      final service = ICloudCloudService();

      await expectLater(service.reauthenticateIfNeeded(), throwsA(isA<Exception>()));
    });

    // Regression test for the bug where re-enabling iCloud after it was
    // toggled off in Settings silently reset autoBackupEnabled to true,
    // because _currentUser (in-memory) gets nulled on every "unavailable"
    // check and was the only thing consulted to decide "is this the same
    // account" — the persisted record must be consulted too.
    test('same-account re-enable preserves autoBackupEnabled after it was turned off', () async {
      mockNative(available: true, accountId: 'record-a');
      final service = ICloudCloudService();
      await service.signIn();
      service.setAutoBackupEnabled(false);
      expect(service.currentUser?.autoBackupEnabled, isFalse);

      // Simulate the OS toggle being turned off, then back on for the same
      // account — the in-memory _currentUser is nulled in between.
      mockNative(available: false);
      await service.signIn();
      expect(service.currentUser, isNull);

      mockNative(available: true, accountId: 'record-a');
      await service.signIn();

      expect(service.currentUser?.accountId, 'record-a');
      expect(
        service.currentUser?.autoBackupEnabled,
        isFalse,
        reason: 'reconnecting the same account must not silently re-enable automatic backup',
      );
    });

    test('account switch replaces the stored user with a fresh one', () async {
      mockNative(available: true, accountId: 'record-a');
      final service = ICloudCloudService();
      await service.signIn();
      service.setAutoBackupEnabled(false);

      mockNative(available: true, accountId: 'record-b');
      await service.signIn();

      expect(service.currentUser?.accountId, 'record-b');
      expect(
        service.currentUser?.autoBackupEnabled,
        isTrue,
        reason: 'a genuinely different account must not inherit the old account\'s preference',
      );
    });

    test('signOut clears both the in-memory and persisted user', () async {
      mockNative(available: true, accountId: 'record-a');
      final service = ICloudCloudService();
      await service.signIn();

      await service.signOut();

      expect(service.currentUser, isNull);
      // Check storage directly rather than re-initializing a fresh service:
      // iCloud has no real "sign out" (see ICloudCloudService's class doc) —
      // if the device is still available, a fresh initialize() legitimately
      // reconnects immediately, which is intentional and not what this test
      // is about. This confirms signOut() actually cleared the persisted
      // record, independent of that live re-check.
      expect(await ICloudUserStorage().readObject(), isNull);
    });
  });
}
