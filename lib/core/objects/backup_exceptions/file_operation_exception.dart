part of 'backup_exception.dart';

enum FileOperationType {
  upload,
  download,
  delete,
  list,
}

/// File operation exceptions
class FileOperationException extends BackupException {
  final FileOperationType operation;

  const FileOperationException(
    super.message,
    this.operation, {
    super.context,
    super.isRetryable = true,
  });

  @override
  String get userFriendlyMessage {
    switch (operation) {
      case FileOperationType.upload:
        return 'Failed to upload backup. Please try again.';
      case FileOperationType.download:
        return 'Failed to download backup. Please check your connection and try again.';
      case FileOperationType.delete:
        return 'Failed to delete backup file. Please try again.';
      case FileOperationType.list:
        return 'Failed to load backup files. Please check your connection and try again.';
    }
  }
}
