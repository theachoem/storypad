import 'package:storypad/core/services/backups/backup_service_type.dart';

part 'auth_exception.dart';
part 'configuration_exception.dart';
part 'file_operation_exception.dart';
part 'network_exception.dart';
part 'quota_exception.dart';
part 'service_exception.dart';

/// Base exception for all backup-related errors
abstract class BackupException implements Exception {
  final String message;
  final String? context;
  final bool isRetryable;
  final BackupServiceType? serviceType;

  const BackupException(
    this.message, {
    this.context,
    this.isRetryable = false,
    required this.serviceType,
  });

  @override
  String toString() => 'BackupException: $message${context != null ? ' ($context)' : ''}';

  /// Creates user-friendly error message for UI display
  String get userFriendlyMessage => message;
}
