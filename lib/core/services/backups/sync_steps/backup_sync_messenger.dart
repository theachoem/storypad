import 'dart:async';

import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/backups/sync_steps/sync_step.dart';

/// Single broadcast channel for step-progress messages across every
/// [BackupServiceType] — replaces one [StreamController] per step service.
/// Every message already carries its own serviceType/step, so a listener
/// (`BackupSyncStateStore`) can attribute updates directly instead of
/// guessing from which controller emitted it.
class BackupSyncMessenger {
  final StreamController<BackupSyncMessage> _controller = StreamController<BackupSyncMessage>.broadcast();
  Stream<BackupSyncMessage> get messages => _controller.stream;

  void report({
    required BackupServiceType serviceType,
    required SyncStep step,
    required bool processing,
    bool? success,
    String? message,
  }) {
    _controller.add(
      BackupSyncMessage(
        processing: processing,
        success: success,
        message: message,
        serviceType: serviceType,
        step: step,
      ),
    );
  }

  void dispose() => _controller.close();
}
