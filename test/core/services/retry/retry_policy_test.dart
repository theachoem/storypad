import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    test('creates with default values', () {
      const policy = RetryPolicy();

      expect(policy.maxAttempts, equals(3));
      expect(policy.initialDelay, equals(const Duration(seconds: 1)));
      expect(policy.maxDelay, equals(const Duration(seconds: 30)));
      expect(policy.backoffMultiplier, equals(2.0));
      expect(
        policy.retryableExceptions,
        equals({
          NetworkException,
          FileOperationException,
        }),
      );
    });

    test('has predefined network policy', () {
      const policy = RetryPolicy.network;

      expect(policy.maxAttempts, equals(3));
      expect(policy.initialDelay, equals(const Duration(seconds: 1)));
      expect(policy.maxDelay, equals(const Duration(seconds: 10)));
      expect(policy.backoffMultiplier, equals(2.0));
    });

    test('has predefined quota policy', () {
      const policy = RetryPolicy.quota;

      expect(policy.maxAttempts, equals(2));
      expect(policy.initialDelay, equals(const Duration(seconds: 5)));
      expect(policy.maxDelay, equals(const Duration(seconds: 60)));
      expect(policy.backoffMultiplier, equals(3.0));
    });

    test('has no retry policy', () {
      const policy = RetryPolicy.none;
      expect(policy.maxAttempts, equals(1));
    });

    test('returns zero delay for attempt 0 or less', () {
      const policy = RetryPolicy();

      expect(policy.calculateDelay(0), equals(Duration.zero));
      expect(policy.calculateDelay(-1), equals(Duration.zero));
    });

    test('calculates exponential backoff', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 2.0,
      );

      expect(policy.calculateDelay(1), equals(const Duration(seconds: 1)));
      expect(policy.calculateDelay(2), equals(const Duration(seconds: 2)));
      expect(policy.calculateDelay(3), equals(const Duration(seconds: 4)));
    });

    test('respects max delay', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 10),
        backoffMultiplier: 2.0,
        maxDelay: Duration(seconds: 15),
      );

      expect(policy.calculateDelay(1), equals(const Duration(seconds: 10)));
      expect(policy.calculateDelay(2), equals(const Duration(seconds: 15))); // Clamped
      expect(policy.calculateDelay(3), equals(const Duration(seconds: 15))); // Clamped
    });

    test('does not retry if max attempts reached', () {
      const policy = RetryPolicy(maxAttempts: 2);
      const exception = NetworkException('Network error');

      expect(policy.shouldRetry(exception, 2), isFalse);
      expect(policy.shouldRetry(exception, 3), isFalse);
    });

    test('retries retryable exceptions only', () {
      const policy = RetryPolicy(
        maxAttempts: 3,
        retryableExceptions: {NetworkException},
      );

      const networkException = NetworkException('Network error');
      const authException = AuthException('Auth error', AuthExceptionType.signInFailed);

      expect(policy.shouldRetry(networkException, 1), isTrue);
      expect(policy.shouldRetry(authException, 1), isFalse);
    });

    test('does not retry non-retryable exceptions', () {
      const policy = RetryPolicy();
      const exception = NetworkException('Network error', isRetryable: false);

      expect(policy.shouldRetry(exception, 1), isFalse);
    });

    test('does not retry non-BackupException', () {
      const policy = RetryPolicy();
      final exception = Exception('Generic error');

      expect(policy.shouldRetry(exception, 1), isFalse);
    });
  });

  group('RateLimitAwareRetryPolicy', () {
    test('parses retry-after header as seconds', () {
      const parseDelay = RateLimitAwareRetryPolicy.parseRetryAfter;

      expect(parseDelay('30'), equals(const Duration(seconds: 30)));
      expect(parseDelay('120'), equals(const Duration(seconds: 120)));
      expect(parseDelay(null), isNull);
      expect(parseDelay('invalid'), isNull);
    });

    test('calculates delay with rate limit', () {
      const policy = RateLimitAwareRetryPolicy(
        initialDelay: Duration(seconds: 1),
        parseRetryAfterHeader: RateLimitAwareRetryPolicy.parseRetryAfter,
      );

      // Without retry-after header, use normal backoff
      expect(policy.calculateDelayWithRateLimit(1, null), equals(const Duration(seconds: 1)));

      // With retry-after header, use that value
      expect(policy.calculateDelayWithRateLimit(1, '30'), equals(const Duration(seconds: 30)));
    });

    test('respects max delay for rate limiting', () {
      const policy = RateLimitAwareRetryPolicy(
        maxDelay: Duration(seconds: 10),
        parseRetryAfterHeader: RateLimitAwareRetryPolicy.parseRetryAfter,
      );

      // Retry-after header is larger than max delay
      expect(policy.calculateDelayWithRateLimit(1, '60'), equals(const Duration(seconds: 10)));
    });
  });
}
