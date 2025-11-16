part of 'backup_exception.dart';

enum ServiceExceptionType {
  validationFailed,
  compressionFailed,
  decompressionFailed,
  dataCorrupted,
  unexpectedError,
}

/// Service-level business logic exceptions
class ServiceException extends BackupException {
  final ServiceExceptionType type;

  const ServiceException(
    super.message,
    this.type, {
    super.context,
    super.isRetryable = false,
    super.serviceType,
  });

  @override
  String get userFriendlyMessage {
    switch (type) {
      case ServiceExceptionType.validationFailed:
        return 'Backup data validation failed. Please contact support.';
      case ServiceExceptionType.compressionFailed:
        return 'Failed to compress backup data. Please try again.';
      case ServiceExceptionType.decompressionFailed:
        return 'Failed to decompress backup data. The backup file may be corrupted.';
      case ServiceExceptionType.dataCorrupted:
        return 'Backup data is corrupted and cannot be restored.';
      case ServiceExceptionType.unexpectedError:
        return 'An unexpected error occurred. Please try again or contact support.';
    }
  }
}
