/// A Result type for safe error handling without exceptions.
/// 
/// This type encapsulates either a success value [T] or an error value [E],
/// allowing for safe composition and transformation of operations that may fail.
sealed class Result<T, E> {
  const Result();

  /// Creates a successful result containing [value].
  const factory Result.success(T value) = Success<T, E>;

  /// Creates an error result containing [error].
  const factory Result.error(E error) = Error<T, E>;

  /// Returns true if this is a success result.
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is an error result.
  bool get isError => this is Error<T, E>;

  /// Returns the success value or throws if this is an error result.
  T get value {
    return switch (this) {
      Success(value: final value) => value,
      Error() => throw StateError('Called value on error result'),
    };
  }

  /// Returns the error value or throws if this is a success result.
  E get error {
    return switch (this) {
      Success() => throw StateError('Called error on success result'),
      Error(error: final error) => error,
    };
  }

  /// Transforms this result using the provided functions.
  /// 
  /// If this is a success result, calls [success] with the value.
  /// If this is an error result, calls [error] with the error.
  R fold<R>({
    required R Function(T value) success,
    required R Function(E error) error,
  }) {
    return switch (this) {
      Success(value: final value) => success(value),
      Error(error: final err) => error(err),
    };
  }

  /// Maps the success value to a new type [U] using [mapper].
  /// Error results are passed through unchanged.
  Result<U, E> map<U>(U Function(T value) mapper) {
    return switch (this) {
      Success(value: final value) => Success(mapper(value)),
      Error(error: final error) => Error(error),
    };
  }

  /// Maps the error value to a new type [F] using [mapper].
  /// Success results are passed through unchanged.
  Result<T, F> mapError<F>(F Function(E error) mapper) {
    return switch (this) {
      Success(value: final value) => Success(value),
      Error(error: final error) => Error(mapper(error)),
    };
  }

  /// Chains another operation that returns a Result.
  /// Only executes [operation] if this is a success result.
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) operation) {
    return switch (this) {
      Success(value: final value) => operation(value),
      Error(error: final error) => Error(error),
    };
  }
}

/// A successful result containing a [value].
final class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// An error result containing an [error].
final class Error<T, E> extends Result<T, E> {
  final E error;

  const Error(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T, E> && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Error($error)';
}