part of 'backup_exception.dart';

/// Network-related exceptions
class NetworkException extends BackupException {
  const NetworkException(super.message, {super.context, super.isRetryable = true});

  @override
  String get userFriendlyMessage => 'Network connection error. Please check your internet connection and try again.';
}
