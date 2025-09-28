import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/retry/retry_policy.dart';
import 'package:storypad/core/types/backup_result.dart';

/// Utility class for executing operations with retry logic
class RetryExecutor {
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryPolicy policy = RetryPolicy.network,
    String? operationName,
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= policy.maxAttempts; attempt++) {
      try {
        // Add timeout if specified
        if (policy.timeout != null) {
          return await operation().timeout(policy.timeout!);
        }
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        if (!policy.shouldRetry(e, attempt)) {
          rethrow;
        }

        if (attempt < policy.maxAttempts) {
          final delay = policy.calculateDelay(attempt);
          if (delay > Duration.zero) {
            await Future.delayed(delay);
          }
        }
      }
    }

    // This should not be reached, but just in case
    throw lastException ??
        exp.ServiceException(
          'Retry executor failed without exception',
          exp.ServiceExceptionType.unexpectedError,
          context: operationName,
        );
  }

  /// Execute operation with BackupResult return type
  static Future<BackupResult<T>> executeWithResult<T>(
    Future<T> Function() operation, {
    RetryPolicy policy = RetryPolicy.network,
    String? operationName,
  }) async {
    try {
      final result = await execute(operation, policy: policy, operationName: operationName);
      return BackupResult.success(result);
    } on exp.BackupException catch (e) {
      return BackupResult.failure(BackupError.fromException(e));
    } on Exception catch (e) {
      return BackupResult.failure(BackupError.unknown(
        e.toString(),
        context: operationName,
      ));
    }
  }
}
