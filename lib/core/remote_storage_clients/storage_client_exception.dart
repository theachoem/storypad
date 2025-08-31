enum StorageClientExceptionType {
  noInternet,
  unauthorizedRevokedOrExpired,
  unauthorizedMissingScope,
  requestFailed,
  unknown,
}

class StorageClientException {
  final StorageClientExceptionType type;
  final String? message;
  final StackTrace? stackTrace;

  StorageClientException({
    required this.type,
    this.message,
    this.stackTrace,
  });

  factory StorageClientException.noInternet() {
    return StorageClientException(
      type: StorageClientExceptionType.noInternet,
    );
  }

  static StorageClientException unauthorizedMissingScope() {
    return StorageClientException(
      type: StorageClientExceptionType.unauthorizedMissingScope,
    );
  }

  static StorageClientException requestFailed([Object? error, StackTrace? stackTrace]) {
    return StorageClientException(
      type: StorageClientExceptionType.requestFailed,
      message: error.toString(),
      stackTrace: stackTrace,
    );
  }

  static StorageClientException unknownError([Object? error, StackTrace? stackTrace]) {
    return StorageClientException(
      type: StorageClientExceptionType.unknown,
      message: error.toString(),
      stackTrace: stackTrace,
    );
  }
}
