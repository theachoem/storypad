import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/sync_step.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/providers/backup_sync_state_store.dart';

void main() {
  group('BackupSyncStateStore', () {
    late BackupSyncStateStore store;

    setUp(() {
      store = BackupSyncStateStore();
    });

    test('statusFor an untouched service is idle with no data', () {
      final status = store.statusFor(BackupServiceType.google_drive);

      expect(status.activity, SyncActivity.idle);
      expect(status.currentStep, isNull);
      expect(status.message, isNull);
      expect(status.connectionStatus, isNull);
      expect(status.lastSyncedAt, isNull);
    });

    test('onSyncMessage marks that service active with the message step', () {
      store.onSyncMessage(
        BackupSyncMessage(
          processing: true,
          success: null,
          message: 'uploading...',
          serviceType: BackupServiceType.google_drive,
          step: SyncStep.uploadAssets,
        ),
      );

      final status = store.statusFor(BackupServiceType.google_drive);
      expect(status.activity, SyncActivity.active);
      expect(status.currentStep, SyncStep.uploadAssets);
      expect(status.message, 'uploading...');
    });

    // The exact regression this store exists to prevent: interleaved
    // messages from two services must never cross-contaminate.
    test('interleaved messages for two services never cross-contaminate', () {
      store.onSyncMessage(
        BackupSyncMessage(
          processing: true,
          success: null,
          message: 'drive step 1',
          serviceType: BackupServiceType.google_drive,
          step: SyncStep.uploadAssets,
        ),
      );
      store.onSyncMessage(
        BackupSyncMessage(
          processing: true,
          success: null,
          message: 'nextcloud step 1',
          serviceType: BackupServiceType.nextcloud,
          step: SyncStep.uploadAssets,
        ),
      );
      store.onSyncMessage(
        BackupSyncMessage(
          processing: true,
          success: null,
          message: 'drive step 2',
          serviceType: BackupServiceType.google_drive,
          step: SyncStep.checkLatest,
        ),
      );

      final drive = store.statusFor(BackupServiceType.google_drive);
      final nextcloud = store.statusFor(BackupServiceType.nextcloud);

      expect(drive.currentStep, SyncStep.checkLatest);
      expect(drive.message, 'drive step 2');
      expect(nextcloud.currentStep, SyncStep.uploadAssets);
      expect(nextcloud.message, 'nextcloud step 1');
    });

    test('onConnectionChecked sets connectionStatus only for the services in the map', () {
      store.onConnectionChecked({
        BackupServiceType.google_drive: BackupConnectionStatus.readyToSync,
        BackupServiceType.nextcloud: BackupConnectionStatus.needServicePermission,
      });

      expect(store.statusFor(BackupServiceType.google_drive).connectionStatus, BackupConnectionStatus.readyToSync);
      expect(
        store.statusFor(BackupServiceType.nextcloud).connectionStatus,
        BackupConnectionStatus.needServicePermission,
      );
    });

    test('onSyncQueueStarted marks every listed service queued', () {
      store.onSyncQueueStarted([BackupServiceType.google_drive, BackupServiceType.nextcloud]);

      expect(store.statusFor(BackupServiceType.google_drive).activity, SyncActivity.queued);
      expect(store.statusFor(BackupServiceType.nextcloud).activity, SyncActivity.queued);
    });

    test('onServiceSyncStarted clears any leftover step/message from a previous run', () {
      store.onSyncMessage(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'stale from last run',
          serviceType: BackupServiceType.google_drive,
          step: SyncStep.uploadBackup,
        ),
      );

      store.onServiceSyncStarted(BackupServiceType.google_drive);

      final status = store.statusFor(BackupServiceType.google_drive);
      expect(status.activity, SyncActivity.active);
      expect(status.currentStep, isNull);
      expect(status.message, isNull);
    });

    test('onServiceSyncFinished goes idle and records lastSyncedAt', () {
      final syncedAt = DateTime(2026, 1, 1);
      store.onServiceSyncStarted(BackupServiceType.google_drive);
      store.onServiceSyncFinished(BackupServiceType.google_drive, lastSyncedAt: syncedAt);

      final status = store.statusFor(BackupServiceType.google_drive);
      expect(status.activity, SyncActivity.idle);
      expect(status.currentStep, isNull);
      expect(status.lastSyncedAt, syncedAt);
    });

    test('onServiceSyncFinished without lastSyncedAt keeps the previous value', () {
      final syncedAt = DateTime(2026, 1, 1);
      store.onServiceSyncFinished(BackupServiceType.google_drive, lastSyncedAt: syncedAt);
      store.onServiceSyncStarted(BackupServiceType.google_drive);
      store.onServiceSyncFinished(BackupServiceType.google_drive); // failed run, no new timestamp

      expect(store.statusFor(BackupServiceType.google_drive).lastSyncedAt, syncedAt);
    });

    test('onSyncFinished clears any service left queued/active if the run ended early', () {
      store.onSyncQueueStarted([BackupServiceType.google_drive, BackupServiceType.nextcloud]);
      store.onServiceSyncStarted(BackupServiceType.google_drive);
      // nextcloud never got its turn — the batch aborted early.

      store.onSyncFinished();

      expect(store.statusFor(BackupServiceType.google_drive).activity, SyncActivity.idle);
      expect(store.statusFor(BackupServiceType.nextcloud).activity, SyncActivity.idle);
    });

    test('resetService clears everything known about that service', () {
      store.onConnectionChecked({BackupServiceType.google_drive: BackupConnectionStatus.needServicePermission});
      store.onServiceSyncFinished(BackupServiceType.google_drive, lastSyncedAt: DateTime(2026, 1, 1));

      store.resetService(BackupServiceType.google_drive);

      final status = store.statusFor(BackupServiceType.google_drive);
      expect(status.connectionStatus, isNull);
      expect(status.lastSyncedAt, isNull);
      expect(status.activity, SyncActivity.idle);
    });

    test('notifies listeners on every mutation', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.onSyncQueueStarted([BackupServiceType.google_drive]);
      store.onServiceSyncStarted(BackupServiceType.google_drive);
      store.onServiceSyncFinished(BackupServiceType.google_drive);

      expect(notifications, 3);
    });
  });
}
