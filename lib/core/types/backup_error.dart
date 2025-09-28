/// Categories of backup-related errors.
enum BackupErrorType {
  /// Authentication-related errors (sign-in, permissions, tokens).
  authentication,
  
  /// Network connectivity issues.
  network,
  
  /// Google Drive API errors (quota, rate limits, API failures).
  googleDriveApi,
  
  /// Local storage or database errors.
  localStorage,
  
  /// File system errors (read, write, permissions).
  fileSystem,
  
  /// Data serialization/deserialization errors.
  serialization,
  
  /// Unknown or unexpected errors.
  unknown,
}

/// Structured error information for backup operations. 
/// 
/// This class provides detailed error information with user-friendly messages
/// and specific error codes for different types of backup failures.
class BackupError {
  final BackupErrorType type;
  final String code;
  final String message;
  final String? details;
  final Object? originalError;

  const BackupError._({
    required this.type,
    required this.code,
    required this.message,
    this.details,
    this.originalError,
  });

  // Authentication Errors
  static BackupError signInFailed([String? details]) => BackupError._(
        type: BackupErrorType.authentication,
        code: 'SIGN_IN_FAILED',
        message: 'Failed to sign in to Google Drive',
        details: details,
      );

  static BackupError signInCancelled() => const BackupError._(
        type: BackupErrorType.authentication,
        code: 'SIGN_IN_CANCELLED',
        message: 'Sign in was cancelled by user',
      );

  static BackupError insufficientPermissions() => const BackupError._(
        type: BackupErrorType.authentication,
        code: 'INSUFFICIENT_PERMISSIONS',
        message: 'Google Drive permissions not granted',
      );

  static BackupError tokenExpired() => const BackupError._(
        type: BackupErrorType.authentication,
        code: 'TOKEN_EXPIRED',
        message: 'Authentication token has expired',
      );

  // Network Errors
  static BackupError networkError([String? details]) => BackupError._(
        type: BackupErrorType.network,
        code: 'NETWORK_ERROR',
        message: 'Network connection failed',
        details: details,
      );

  static BackupError noInternet() => const BackupError._(
        type: BackupErrorType.network,
        code: 'NO_INTERNET',
        message: 'No internet connection available',
      );

  static BackupError timeout() => const BackupError._(
        type: BackupErrorType.network,
        code: 'TIMEOUT',
        message: 'Operation timed out',
      );

  // Google Drive API Errors
  static BackupError quotaExceeded() => const BackupError._(
        type: BackupErrorType.googleDriveApi,
        code: 'QUOTA_EXCEEDED',
        message: 'Google Drive storage quota exceeded',
      );

  static BackupError rateLimitExceeded() => const BackupError._(
        type: BackupErrorType.googleDriveApi,
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests to Google Drive API',
      );

  static BackupError uploadFailed([String? details]) => BackupError._(
        type: BackupErrorType.googleDriveApi,
        code: 'UPLOAD_FAILED',
        message: 'Failed to upload file to Google Drive',
        details: details,
      );

  static BackupError downloadFailed([String? details]) => BackupError._(
        type: BackupErrorType.googleDriveApi,
        code: 'DOWNLOAD_FAILED',
        message: 'Failed to download file from Google Drive',
        details: details,
      );

  static BackupError fileNotFound(String fileName) => BackupError._(
        type: BackupErrorType.googleDriveApi,
        code: 'FILE_NOT_FOUND',
        message: 'File not found on Google Drive',
        details: 'File: $fileName',
      );

  // Local Storage Errors
  static BackupError databaseError([String? details]) => BackupError._(
        type: BackupErrorType.localStorage,
        code: 'DATABASE_ERROR',
        message: 'Local database operation failed',
        details: details,
      );

  static BackupError backupCorrupted() => const BackupError._(
        type: BackupErrorType.localStorage,
        code: 'BACKUP_CORRUPTED',
        message: 'Backup file is corrupted or invalid',
      );

  // File System Errors
  static BackupError fileReadError(String filePath) => BackupError._(
        type: BackupErrorType.fileSystem,
        code: 'FILE_READ_ERROR',
        message: 'Failed to read file',
        details: 'Path: $filePath',
      );

  static BackupError fileWriteError(String filePath) => BackupError._(
        type: BackupErrorType.fileSystem,
        code: 'FILE_WRITE_ERROR',
        message: 'Failed to write file',
        details: 'Path: $filePath',
      );

  static BackupError insufficientStorage() => const BackupError._(
        type: BackupErrorType.fileSystem,
        code: 'INSUFFICIENT_STORAGE',
        message: 'Insufficient local storage space',
      );

  // Serialization Errors
  static BackupError serializationError([String? details]) => BackupError._(
        type: BackupErrorType.serialization,
        code: 'SERIALIZATION_ERROR',
        message: 'Failed to serialize backup data',
        details: details,
      );

  static BackupError deserializationError([String? details]) => BackupError._(
        type: BackupErrorType.serialization,
        code: 'DESERIALIZATION_ERROR',
        message: 'Failed to deserialize backup data',
        details: details,
      );

  // General Errors
  static BackupError maxRetriesExceeded() => const BackupError._(
        type: BackupErrorType.unknown,
        code: 'MAX_RETRIES_EXCEEDED',
        message: 'Maximum retry attempts exceeded',
      );

  static BackupError unknown(String message, [Object? originalError]) => BackupError._(
        type: BackupErrorType.unknown,
        code: 'UNKNOWN_ERROR',
        message: message,
        originalError: originalError,
      );

  /// Returns a user-friendly message for this error.
  String get userFriendlyMessage {
    return switch (type) {
      BackupErrorType.authentication => _getAuthMessage(),
      BackupErrorType.network => _getNetworkMessage(),
      BackupErrorType.googleDriveApi => _getApiMessage(),
      BackupErrorType.localStorage => _getLocalStorageMessage(),
      BackupErrorType.fileSystem => _getFileSystemMessage(),
      BackupErrorType.serialization => _getSerializationMessage(),
      BackupErrorType.unknown => message,
    };
  }

  String _getAuthMessage() {
    return switch (code) {
      'SIGN_IN_CANCELLED' => 'Please sign in to Google Drive to sync your data.',
      'INSUFFICIENT_PERMISSIONS' => 'Please grant Google Drive permissions to backup your stories.',
      'TOKEN_EXPIRED' => 'Your Google Drive session has expired. Please sign in again.',
      _ => 'Authentication error. Please try signing in again.',
    };
  }

  String _getNetworkMessage() {
    return switch (code) {
      'NO_INTERNET' => 'No internet connection. Please check your network and try again.',
      'TIMEOUT' => 'Connection timed out. Please try again.',
      _ => 'Network error. Please check your connection and try again.',
    };
  }

  String _getApiMessage() {
    return switch (code) {
      'QUOTA_EXCEEDED' => 'Your Google Drive storage is full. Please free up space and try again.',
      'RATE_LIMIT_EXCEEDED' => 'Too many requests. Please wait a moment and try again.',
      'FILE_NOT_FOUND' => 'Backup file not found on Google Drive.',
      _ => 'Google Drive error. Please try again later.',
    };
  }

  String _getLocalStorageMessage() {
    return switch (code) {
      'BACKUP_CORRUPTED' => 'The backup file is corrupted and cannot be restored.',
      _ => 'Local storage error. Please restart the app and try again.',
    };
  }

  String _getFileSystemMessage() {
    return switch (code) {
      'INSUFFICIENT_STORAGE' => 'Not enough storage space on your device.',
      _ => 'File system error. Please check your device storage.',
    };
  }

  String _getSerializationMessage() {
    return 'Data format error. Please contact support if this persists.';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupError &&
          type == other.type &&
          code == other.code &&
          message == other.message &&
          details == other.details;

  @override
  int get hashCode => Object.hash(type, code, message, details);

  @override
  String toString() {
    final buffer = StringBuffer('BackupError(');
    buffer.write('type: $type, ');
    buffer.write('code: $code, ');
    buffer.write('message: $message');
    if (details != null) {
      buffer.write(', details: $details');
    }
    if (originalError != null) {
      buffer.write(', originalError: $originalError');
    }
    buffer.write(')');
    return buffer.toString();
  }
}