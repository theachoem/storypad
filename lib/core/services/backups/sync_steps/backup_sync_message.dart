class BackupSyncMessage {
  final bool processing;
  final bool? success;
  final String? message;

  BackupSyncMessage({
    required this.processing,
    required this.success,
    required this.message,
  });
}
