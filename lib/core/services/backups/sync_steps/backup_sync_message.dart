import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/sync_steps/sync_step.dart';

class BackupSyncMessage {
  final bool processing;
  final bool? success;
  final String? message;
  final BackupServiceType serviceType;
  final SyncStep step;

  BackupSyncMessage({
    required this.processing,
    required this.success,
    required this.message,
    required this.serviceType,
    required this.step,
  });
}
