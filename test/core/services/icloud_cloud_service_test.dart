import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/objects/icloud_user_object.dart';
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
  /// `isAvailable`; [accountId] (or [accountIdError]) backs `fetchAccountId`;
  /// [fingerprint] backs `fetchIdentityTokenFingerprint` — defaults to a
  /// fixed value so tests that don't care about it (most of them) keep
  /// behaving as if nothing local ever changed between calls. Pass a
  /// different value to simulate the local iCloud identity actually
  /// changing (e.g. to exercise the account-switch-during-transient-failure
  /// guard).
  void mockNative({
    required bool available,
    String? accountId,
    PlatformException? accountIdError,
    String? fingerprint = 'stable-fingerprint',
  }) {
    messenger.setMockMethodCallHandler(nativeChannel, (call) async {
      switch (call.method) {
        case 'ICloudBackupService.isAvailable':
          return available;
        case 'ICloudBackupService.fetchAccountId':
          if (accountIdError != null) throw accountIdError;
          return accountId;
        case 'ICloudBackupService.fetchIdentityTokenFingerprint':
          return fingerprint;
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

    // Regression test for the account-switch race Copilot flagged on PR
    // #725: a cached account can't prove the *current* ubiquity container
    // still belongs to it. If the local iCloud identity changed while
    // fetchAccountId happens to fail transiently, the cache must not be
    // trusted — otherwise the old account's bookkeeping/RevenueCat identity
    // could keep being used while files are actually written to the new
    // account's container.
    test(
      'transient network failure where the local identity changed does not trust the cache',
      () async {
        mockNative(available: true, accountId: 'record-a', fingerprint: 'token-a');
        final service = ICloudCloudService();
        await service.signIn();
        expect(service.currentUser?.identityTokenFingerprint, 'token-a');

        // Simulate an account switch (A -> B) landing at the exact moment
        // the CloudKit identity fetch fails transiently: the local token has
        // already changed, but fetchAccountId can't confirm the new account.
        mockNative(
          available: true,
          accountIdError: PlatformException(code: 'NETWORK'),
          fingerprint: 'token-b',
        );

        await expectLater(
          service.signIn(),
          throwsA(isA<NetworkException>()),
          reason: 'a changed local identity must not fall back to the old cached account',
        );
        expect(
          service.currentUser,
          isNull,
          reason: 'must not keep exposing account A as signed in once the local identity no longer matches it',
        );
      },
    );

    // Same guard, but verified across a fresh app launch rather than within
    // one running service instance — the fingerprint has to be persisted
    // (not just held in memory) for this to work on a cold start.
    test(
      'transient network failure on a fresh launch with a persisted user but no recorded fingerprint does not trust it',
      () async {
        mockNative(available: true, accountId: 'record-a', fingerprint: 'token-a');
        final service = ICloudCloudService();
        await service.signIn();

        // A record from before this fingerprint existed (or one that just
        // never got a successful confirmation yet).
        final stored = await ICloudUserStorage().readObject();
        await ICloudUserStorage().writeObject(stored!.copyWith(identityTokenFingerprint: null));

        final freshLaunch = ICloudCloudService();
        mockNative(
          available: true,
          accountIdError: PlatformException(code: 'NETWORK'),
          fingerprint: 'token-a',
        );
        await freshLaunch.initialize();

        expect(
          freshLaunch.currentUser,
          isNull,
          reason: 'no recorded fingerprint to compare against means the match can\'t be confirmed',
        );
      },
    );

    // A bare `false` here would be indistinguishable from iCloud actually
    // being disabled — the caller (BackupProvider.signIn) would send an
    // offline first-time user to Settings guidance that can't help them, so
    // this must throw instead. See icloud_cloud_service.dart's signIn doc.
    test(
      'signIn throws NetworkException on a transient failure with no cached user, without wiping anything',
      () async {
        mockNative(available: true, accountIdError: PlatformException(code: 'NETWORK'));
        final service = ICloudCloudService();

        await expectLater(service.signIn(), throwsA(isA<NetworkException>()));
        expect(service.currentUser, isNull);
      },
    );

    test('reauthenticateIfNeeded throws NetworkException on a transient failure with no cached user', () async {
      mockNative(available: true, accountIdError: PlatformException(code: 'NETWORK'));
      final service = ICloudCloudService();

      await expectLater(service.reauthenticateIfNeeded(), throwsA(isA<NetworkException>()));
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
