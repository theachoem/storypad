/// Base exception for Google Drive operations.
/// 
/// All Google Drive client exceptions extend from this base class
/// to provide consistent error handling.
abstract class GoogleDriveException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? originalStackTrace;

  const GoogleDriveException(
    this.message, {
    this.originalError,
    this.originalStackTrace,
  });

  @override
  String toString() => 'GoogleDriveException: $message';
}

/// Exception thrown when Google Drive authentication fails.
class GoogleDriveAuthException extends GoogleDriveException {
  const GoogleDriveAuthException(
    super.message, {
    super.originalError,
    super.originalStackTrace,
  });

  /// User is not signed in.
  factory GoogleDriveAuthException.notSignedIn() =>
      const GoogleDriveAuthException('User is not signed in to Google Drive');

  /// Sign-in was cancelled by the user.
  factory GoogleDriveAuthException.signInCancelled() =>
      const GoogleDriveAuthException('Google Drive sign-in was cancelled by user');

  /// Insufficient permissions for Google Drive access.
  factory GoogleDriveAuthException.insufficientPermissions() =>
      const GoogleDriveAuthException('Insufficient Google Drive permissions');

  /// Authentication token has expired.
  factory GoogleDriveAuthException.tokenExpired() =>
      const GoogleDriveAuthException('Google Drive authentication token has expired');

  /// Failed to refresh authentication token.
  factory GoogleDriveAuthException.tokenRefreshFailed([Object? originalError]) =>
      GoogleDriveAuthException(
        'Failed to refresh Google Drive authentication token',
        originalError: originalError,
      );

  @override
  String toString() => 'GoogleDriveAuthException: $message';
}

/// Exception thrown for network-related Google Drive errors.
class GoogleDriveNetworkException extends GoogleDriveException {
  const GoogleDriveNetworkException(
    super.message, {
    super.originalError,
    super.originalStackTrace,
  });

  /// No internet connection available.
  factory GoogleDriveNetworkException.noConnection() =>
      const GoogleDriveNetworkException('No internet connection available');

  /// Network request timed out.
  factory GoogleDriveNetworkException.timeout() =>
      const GoogleDriveNetworkException('Google Drive request timed out');

  /// General network error.
  factory GoogleDriveNetworkException.networkError([Object? originalError]) =>
      GoogleDriveNetworkException(
        'Network error occurred while accessing Google Drive',
        originalError: originalError,
      );

  @override
  String toString() => 'GoogleDriveNetworkException: $message';
}

/// Exception thrown for Google Drive API-specific errors.
class GoogleDriveApiException extends GoogleDriveException {
  final int? statusCode;

  const GoogleDriveApiException(
    super.message, {
    this.statusCode,
    super.originalError,
    super.originalStackTrace,
  });

  /// File not found on Google Drive.
  factory GoogleDriveApiException.fileNotFound(String fileId) =>
      GoogleDriveApiException(
        'File not found on Google Drive: $fileId',
        statusCode: 404,
      );

  /// Failed to upload file to Google Drive.
  factory GoogleDriveApiException.uploadFailed([Object? originalError]) =>
      GoogleDriveApiException(
        'Failed to upload file to Google Drive',
        originalError: originalError,
      );

  /// Failed to download file from Google Drive.
  factory GoogleDriveApiException.downloadFailed(String fileId, [Object? originalError]) =>
      GoogleDriveApiException(
        'Failed to download file from Google Drive: $fileId',
        originalError: originalError,
      );

  /// Failed to delete file from Google Drive.
  factory GoogleDriveApiException.deleteFailed(String fileId, [Object? originalError]) =>
      GoogleDriveApiException(
        'Failed to delete file from Google Drive: $fileId',
        originalError: originalError,
      );

  /// Failed to list files from Google Drive.
  factory GoogleDriveApiException.listFailed([Object? originalError]) =>
      GoogleDriveApiException(
        'Failed to list files from Google Drive',
        originalError: originalError,
      );

  /// Failed to create folder on Google Drive.
  factory GoogleDriveApiException.createFolderFailed(String folderName, [Object? originalError]) =>
      GoogleDriveApiException(
        'Failed to create folder on Google Drive: $folderName',
        originalError: originalError,
      );

  /// Invalid API response from Google Drive.
  factory GoogleDriveApiException.invalidResponse([Object? originalError]) =>
      GoogleDriveApiException(
        'Invalid response from Google Drive API',
        originalError: originalError,
      );

  @override
  String toString() {
    final buffer = StringBuffer('GoogleDriveApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when Google Drive quota is exceeded.
class GoogleDriveQuotaException extends GoogleDriveException {
  const GoogleDriveQuotaException(
    super.message, {
    super.originalError,
    super.originalStackTrace,
  });

  /// Storage quota exceeded.
  factory GoogleDriveQuotaException.storageExceeded() =>
      const GoogleDriveQuotaException('Google Drive storage quota exceeded');

  /// Rate limit exceeded.
  factory GoogleDriveQuotaException.rateLimitExceeded() =>
      const GoogleDriveQuotaException('Google Drive API rate limit exceeded');

  @override
  String toString() => 'GoogleDriveQuotaException: $message';
}