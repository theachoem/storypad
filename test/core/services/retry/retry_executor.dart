import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/types/backup_result.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

void main() {
  group('RetryExecutor', () {
    test('executes operation successfully on first try', () async {
      var callCount = 0;

      final result = await RetryExecutor.execute(() async {
        callCount++;
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(1));
    });

    test('retries on retryable exception', () async {
      var callCount = 0;

      final result = await RetryExecutor.execute(() async {
        callCount++;
        if (callCount < 3) {
          throw const NetworkException('Network error');
        }
        return 'success after retry';
      });

      expect(result, equals('success after retry'));
      expect(callCount, equals(3));
    });

    test('does not retry non-retryable exception', () async {
      var callCount = 0;

      expect(
          () async => await RetryExecutor.execute(() async {
                callCount++;
                throw const AuthException('Auth error', AuthExceptionType.signInFailed);
              }),
          throwsA(isA<AuthException>()));

      expect(callCount, equals(1));
    });

    test('respects max attempts', () async {
      var callCount = 0;
      const policy = RetryPolicy(
        maxAttempts: 2,
        retryableExceptions: {NetworkException},
      );

      try {
        await RetryExecutor.execute(() async {
          callCount++;
          throw const NetworkException('Network error');
        }, policy: policy);
      } catch (e) {
        // Expected to throw after max attempts
      }

      expect(callCount, equals(2));
    });

    test('handles timeout when specified', () async {
      const policy = RetryPolicy(
        timeout: Duration(milliseconds: 100),
        maxAttempts: 1,
      );

      expect(
          () async => await RetryExecutor.execute(() async {
                await Future.delayed(const Duration(milliseconds: 200));
                return 'should not complete';
              }, policy: policy),
          throwsA(isA<Exception>()));
    });

    test('returns success result with executeWithResult', () async {
      final result = await RetryExecutor.executeWithResult(() async {
        return 'success';
      });

      expect(result.isSuccess, isTrue);
      expect(result.data, equals('success'));
    });

    test('returns failure result for BackupException', () async {
      final result = await RetryExecutor.executeWithResult(() async {
        throw const NetworkException('Network error');
      }, policy: RetryPolicy.none);

      expect(result.isFailure, isTrue);
      expect(result.error?.type, equals(BackupErrorType.network));
      expect(result.error?.message, equals('Network error'));
    });

    test('returns failure result for generic exception', () async {
      final result = await RetryExecutor.executeWithResult(() async {
        throw Exception('Generic error');
      }, policy: RetryPolicy.none);

      expect(result.isFailure, isTrue);
      expect(result.error?.type, equals(BackupErrorType.unknown));
    });
  });
}
