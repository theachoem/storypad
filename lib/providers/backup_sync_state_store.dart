import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/sync_step.dart';
import 'package:storypad/core/types/backup_connection_status.dart';

part 'backup_sync_state_store.g.dart';

enum SyncActivity { idle, queued, active }

/// One service's own sync/connection state — never a cross-service merge.
/// "Did the last run succeed" isn't a separate field: derive it from
/// [connectionStatus] == readyToSync plus whether [lastSyncedAt] just moved,
/// so there's one less thing to keep in sync or reset correctly.
@CopyWith()
class ServiceSyncStatus {
  final SyncActivity activity;
  final SyncStep? currentStep;
  final String? message;
  final BackupConnectionStatus? connectionStatus;
  final DateTime? lastSyncedAt;

  const ServiceSyncStatus({
    this.activity = SyncActivity.idle,
    this.currentStep,
    this.message,
    this.connectionStatus,
    this.lastSyncedAt,
  });

  static const idle = ServiceSyncStatus();
}

/// Per-service sync/connection state, derived purely from explicit events —
/// no dependency on BackupRepository, Firebase, or BuildContext, so it's
/// unit-testable without mocking any of those. BackupProvider owns one
/// instance and forwards repository events into it.
class BackupSyncStateStore extends ChangeNotifier {
  final Map<BackupServiceType, ServiceSyncStatus> _statusByService = {};

  ServiceSyncStatus statusFor(BackupServiceType type) => _statusByService[type] ?? ServiceSyncStatus.idle;

  /// Clears everything known about a service — e.g. an explicit sign-out,
  /// where the account itself is gone, not just its sync progress.
  void resetService(BackupServiceType type) {
    _statusByService.remove(type);
    notifyListeners();
  }

  /// A step-progress update for one service, mid-run.
  void onSyncMessage(BackupSyncMessage message) {
    final current = statusFor(message.serviceType);
    _statusByService[message.serviceType] = current.copyWith(
      activity: SyncActivity.active,
      currentStep: message.step,
      message: message.message,
    );
    notifyListeners();
  }

  /// Results of a connection check — one status per currently signed-in
  /// service, never just the first one that failed.
  void onConnectionChecked(Map<BackupServiceType, BackupConnectionStatus> statusByService) {
    for (final entry in statusByService.entries) {
      final current = statusFor(entry.key);
      _statusByService[entry.key] = current.copyWith(connectionStatus: entry.value);
    }
    notifyListeners();
  }

  /// A sync run is about to start for these services — they're queued until
  /// their own turn begins (the run is sequential, one service at a time).
  void onSyncQueueStarted(List<BackupServiceType> queue) {
    for (final type in queue) {
      final current = statusFor(type);
      _statusByService[type] = current.copyWith(activity: SyncActivity.queued);
    }
    notifyListeners();
  }

  /// This service's turn has started — clears the previous run's leftover
  /// step/message so nothing stale can flash before the first new message
  /// arrives.
  void onServiceSyncStarted(BackupServiceType type) {
    final current = statusFor(type);
    _statusByService[type] = ServiceSyncStatus(
      activity: SyncActivity.active,
      currentStep: null,
      message: null,
      connectionStatus: current.connectionStatus,
      lastSyncedAt: current.lastSyncedAt,
    );
    notifyListeners();
  }

  /// This service's turn ended (success or failure alike — failure is
  /// already reflected via [onConnectionChecked]/a later status update).
  /// [lastSyncedAt] is only passed on success; omit it to keep the previous
  /// value.
  void onServiceSyncFinished(BackupServiceType type, {DateTime? lastSyncedAt}) {
    final current = statusFor(type);
    _statusByService[type] = ServiceSyncStatus(
      activity: SyncActivity.idle,
      currentStep: null,
      message: null,
      connectionStatus: current.connectionStatus,
      lastSyncedAt: lastSyncedAt ?? current.lastSyncedAt,
    );
    notifyListeners();
  }

  /// Clears any service left `queued`/`active` if a run ends early (e.g. the
  /// whole batch aborted before reaching every queued service).
  void onSyncFinished() {
    for (final type in _statusByService.keys.toList()) {
      final current = _statusByService[type]!;
      if (current.activity == SyncActivity.idle) continue;

      _statusByService[type] = ServiceSyncStatus(
        activity: SyncActivity.idle,
        currentStep: null,
        message: null,
        connectionStatus: current.connectionStatus,
        lastSyncedAt: current.lastSyncedAt,
      );
    }
    notifyListeners();
  }
}
