import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

/// Represents the result of a backup operation that can either succeed or fail safely
sealed class BackupResult<T> {
  const BackupResult();

  /// Create a successful result
  const factory BackupResult.success(T data) = BackupSuccess<T>;

  /// Create a failed result
  const factory BackupResult.failure(BackupError error) = BackupFailure<T>;

  /// Create a partial success result (some operations succeeded, some failed)
  const factory BackupResult.partialSuccess(T data, List<BackupError> errors) = BackupPartialSuccess<T>;

  /// Returns true if the operation was completely successful
  bool get isSuccess => this is BackupSuccess<T>;

  /// Returns true if the operation completely failed
  bool get isFailure => this is BackupFailure<T>;

  /// Returns true if the operation had partial success
  bool get isPartialSuccess => this is BackupPartialSuccess<T>;

  /// Returns the data if successful, null otherwise
  T? get data => switch (this) {
    BackupSuccess(data: final data) => data,
    BackupPartialSuccess(data: final data) => data,
    BackupFailure() => null,
  };

  /// Returns the primary error if failed, null otherwise
  BackupError? get error => switch (this) {
    BackupFailure(error: final error) => error,
    BackupPartialSuccess(errors: final errors) => errors.firstOrNull,
    BackupSuccess() => null,
  };

  /// Returns all errors for partial success results
  List<BackupError> get errors => switch (this) {
    BackupPartialSuccess(errors: final errors) => errors,
    BackupFailure(error: final error) => [error],
    BackupSuccess() => [],
  };

  /// Transform the success data using the provided function
  BackupResult<U> map<U>(U Function(T) transform) => switch (this) {
    BackupSuccess(data: final data) => BackupResult.success(transform(data)),
    BackupPartialSuccess(data: final data, errors: final errors) => BackupResult.partialSuccess(
      transform(data),
      errors,
    ),
    BackupFailure(error: final error) => BackupResult.failure(error),
  };

  /// Chain another operation that returns a BackupResult
  BackupResult<U> flatMap<U>(BackupResult<U> Function(T) transform) => switch (this) {
    BackupSuccess(data: final data) => transform(data),
    BackupPartialSuccess(data: final data, errors: final errors) => transform(data).addErrors(errors),
    BackupFailure(error: final error) => BackupResult.failure(error),
  };

  /// Add additional errors to the result
  BackupResult<T> addErrors(List<BackupError> additionalErrors) => switch (this) {
    BackupSuccess(data: final data) =>
      additionalErrors.isEmpty ? this : BackupResult.partialSuccess(data, additionalErrors),
    BackupPartialSuccess(data: final data, errors: final errors) => BackupResult.partialSuccess(data, [
      ...errors,
      ...additionalErrors,
    ]),
    BackupFailure() => this,
  };
}

/// Successful result
final class BackupSuccess<T> extends BackupResult<T> {
  @override
  final T data;
  const BackupSuccess(this.data);

  @override
  String toString() => 'BackupSuccess($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BackupSuccess<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failed result
final class BackupFailure<T> extends BackupResult<T> {
  @override
  final BackupError error;
  const BackupFailure(this.error);

  @override
  String toString() => 'BackupFailure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BackupFailure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Partial success result
final class BackupPartialSuccess<T> extends BackupResult<T> {
  @override
  final T data;

  @override
  final List<BackupError> errors;

  const BackupPartialSuccess(this.data, this.errors);

  @override
  String toString() => 'BackupPartialSuccess($data, errors: ${errors.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupPartialSuccess<T> &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          errors.length == other.errors.length &&
          errors.every((e) => other.errors.contains(e));

  @override
  int get hashCode => Object.hash(data, errors);
}

/// Represents a backup operation error with context and retry information
class BackupError {
  final BackupErrorType type;
  final String message;
  final String? context;
  final bool isRetryable;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  BackupError({
    required this.type,
    required this.message,
    this.context,
    this.isRetryable = false,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create error from exception
  factory BackupError.fromException(BackupException exception) {
    final type = switch (exception.runtimeType) {
      const (NetworkException) => BackupErrorType.network,
      const (AuthException) => BackupErrorType.authentication,
      const (QuotaException) => BackupErrorType.quota,
      const (FileOperationException) => BackupErrorType.fileOperation,
      const (ServiceException) => BackupErrorType.service,
      const (ConfigurationException) => BackupErrorType.configuration,
      _ => BackupErrorType.unknown,
    };

    return BackupError(
      type: type,
      message: exception.message,
      context: exception.context,
      isRetryable: exception.isRetryable,
      metadata: exception is AuthException
          ? {'authType': exception.type.name}
          : exception is QuotaException
          ? {'quotaType': exception.type.name}
          : exception is FileOperationException
          ? {'operation': exception.operation.name}
          : exception is ServiceException
          ? {'serviceType': exception.type.name}
          : null,
    );
  }

  /// Create convenience constructors for common error types
  factory BackupError.network(String message, {String? context, bool isRetryable = true}) => BackupError(
    type: BackupErrorType.network,
    message: message,
    context: context,
    isRetryable: isRetryable,
  );

  factory BackupError.authentication(String message, {String? context}) => BackupError(
    type: BackupErrorType.authentication,
    message: message,
    context: context,
    isRetryable: false,
  );

  factory BackupError.quota(String message, {String? context}) => BackupError(
    type: BackupErrorType.quota,
    message: message,
    context: context,
    isRetryable: false,
  );

  factory BackupError.fileOperation(String message, {String? context, bool isRetryable = true}) => BackupError(
    type: BackupErrorType.fileOperation,
    message: message,
    context: context,
    isRetryable: isRetryable,
  );

  factory BackupError.service(String message, {String? context}) => BackupError(
    type: BackupErrorType.service,
    message: message,
    context: context,
    isRetryable: false,
  );

  factory BackupError.unknown(String message, {String? context, bool isRetryable = true}) => BackupError(
    type: BackupErrorType.unknown,
    message: message,
    context: context,
    isRetryable: isRetryable,
  );

  @override
  String toString() => 'BackupError(${type.name}: $message${context != null ? ' ($context)' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupError &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          context == other.context;

  @override
  int get hashCode => Object.hash(type, message, context);
}

/// Types of backup errors for categorization
enum BackupErrorType {
  network,
  authentication,
  quota,
  fileOperation,
  service,
  configuration,
  unknown,
}
