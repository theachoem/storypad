part of 'backup_exception.dart';

enum QuotaExceptionType {
  storageQuotaExceeded,
  rateLimitExceeded,
  dailyLimitExceeded,
}

/// Google Drive API quota and storage exceptions
class QuotaException extends BackupException {
  final QuotaExceptionType type;

  const QuotaException(
    super.message,
    this.type, {
    super.context,
    super.isRetryable = false,
  });

  @override
  String get userFriendlyMessage {
    switch (type) {
      case QuotaExceptionType.storageQuotaExceeded:
        return 'Google Drive storage is full. Please free up space or upgrade your storage plan.';
      case QuotaExceptionType.rateLimitExceeded:
        return 'Too many requests. Please wait a moment before trying again.';
      case QuotaExceptionType.dailyLimitExceeded:
        return 'Daily API limit reached. Please try again tomorrow.';
    }
  }
}
