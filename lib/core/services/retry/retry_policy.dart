import 'dart:math';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;

/// Configuration for retry behavior
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final Set<Type> retryableExceptions;
  final Duration? timeout;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableExceptions = const {
      exp.NetworkException,
      exp.FileOperationException,
    },
    this.timeout,
  });

  /// Default retry policy for network operations
  static const RetryPolicy network = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
    retryableExceptions: {exp.NetworkException, exp.FileOperationException},
  );

  /// Default retry policy for quota-limited operations
  static const RetryPolicy quota = RetryPolicy(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 5),
    maxDelay: Duration(seconds: 60),
    backoffMultiplier: 3.0,
    retryableExceptions: {exp.QuotaException},
  );

  /// No retry policy
  static const RetryPolicy none = RetryPolicy(maxAttempts: 1);

  /// Calculate delay for a specific attempt
  Duration calculateDelay(int attempt) {
    if (attempt <= 0) return Duration.zero;

    final delay = initialDelay * pow(backoffMultiplier, attempt - 1);
    final delayMs = delay.inMilliseconds.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: delayMs);
  }

  /// Check if an exception should trigger a retry
  bool shouldRetry(Exception exception, int currentAttempt) {
    if (currentAttempt >= maxAttempts) return false;

    if (exception is exp.BackupException) {
      return exception.isRetryable && retryableExceptions.contains(exception.runtimeType);
    }

    return false;
  }
}

/// Extended retry policy with rate limiting awareness
class RateLimitAwareRetryPolicy extends RetryPolicy {
  final Duration? Function(String? retryAfterHeader)? parseRetryAfterHeader;

  const RateLimitAwareRetryPolicy({
    super.maxAttempts,
    super.initialDelay,
    super.maxDelay,
    super.backoffMultiplier,
    super.retryableExceptions,
    super.timeout,
    this.parseRetryAfterHeader,
  });

  /// Parse Retry-After header from HTTP response
  static Duration? parseRetryAfter(String? retryAfterHeader) {
    if (retryAfterHeader == null) return null;

    // Try parsing as seconds first
    final seconds = int.tryParse(retryAfterHeader);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }

    // Try parsing as HTTP date (not implemented for simplicity)
    // In a real implementation, you'd parse HTTP date format
    return null;
  }

  /// Calculate delay considering rate limiting
  Duration calculateDelayWithRateLimit(int attempt, String? retryAfterHeader) {
    final retryAfterDelay = parseRetryAfterHeader?.call(retryAfterHeader);
    if (retryAfterDelay != null) {
      return Duration(milliseconds: retryAfterDelay.inMilliseconds.clamp(0, maxDelay.inMilliseconds));
    }

    return calculateDelay(attempt);
  }
}
