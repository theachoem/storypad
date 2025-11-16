part of 'backup_exception.dart';

enum AuthExceptionType {
  tokenExpired,
  tokenRevoked,
  insufficientScopes,
  signInRequired,
  signInFailed,
}

/// Google authentication and authorization exceptions
class AuthException extends BackupException {
  final AuthExceptionType type;

  const AuthException(
    super.message,
    this.type, {
    super.context,
    super.isRetryable = false,
    super.serviceType,
  });

  @override
  String get userFriendlyMessage {
    switch (type) {
      case AuthExceptionType.tokenExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthExceptionType.tokenRevoked:
        return 'Access has been revoked. Please sign in again to continue using backup.';
      case AuthExceptionType.insufficientScopes:
        return 'Additional permissions are required for backup functionality.';
      case AuthExceptionType.signInRequired:
        return 'Please sign in to Google Drive to use backup features.';
      case AuthExceptionType.signInFailed:
        return 'Failed to sign in to Google Drive. Please try again.';
    }
  }

  bool get requiresSignOut => type == AuthExceptionType.tokenRevoked;
  bool get requiresReauth => type == AuthExceptionType.tokenExpired || type == AuthExceptionType.signInRequired;
  bool get requiresScopeRequest => type == AuthExceptionType.insufficientScopes;
}
