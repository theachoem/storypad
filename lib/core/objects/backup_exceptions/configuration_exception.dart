part of 'backup_exception.dart';

/// Configuration or setup related exceptions
class ConfigurationException extends BackupException {
  const ConfigurationException(
    super.message, {
    super.context,
    super.isRetryable = false,
    super.serviceType,
  });

  @override
  String get userFriendlyMessage => 'Configuration error. Please restart the app or contact support.';
}
