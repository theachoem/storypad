import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/types/backup_result.dart';

void main() {
  group('BackupSuccess', () {
    test('creates successful result', () {
      const result = BackupResult.success('test data');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.isPartialSuccess, isFalse);
      expect(result.data, equals('test data'));
      expect(result.error, isNull);
      expect(result.errors, isEmpty);
    });

    test('supports equality', () {
      const result1 = BackupResult.success('test');
      const result2 = BackupResult.success('test');
      const result3 = BackupResult.success('different');

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });

  group('BackupFailure', () {
    test('creates failed result', () {
      final error = BackupError.network('Network error');
      final result = BackupResult<String>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.isPartialSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.error, equals(error));
      expect(result.errors, equals([error]));
    });
  });

  group('BackupPartialSuccess', () {
    test('creates partial success result', () {
      final error1 = BackupError.network('Error 1');
      final error2 = BackupError.fileOperation('Error 2');
      final result = BackupResult.partialSuccess('partial data', [error1, error2]);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.isPartialSuccess, isTrue);
      expect(result.data, equals('partial data'));
      expect(result.error, equals(error1)); // First error
      expect(result.errors, equals([error1, error2]));
    });
  });

  group('BackupResult Transformations', () {
    test('maps success result', () {
      const result = BackupResult.success(5);
      final mapped = result.map((value) => value.toString());

      expect(mapped.isSuccess, isTrue);
      expect(mapped.data, equals('5'));
    });

    test('maps partial success result', () {
      final error = BackupError.network('Error');
      final result = BackupResult.partialSuccess(5, [error]);
      final mapped = result.map((value) => value.toString());

      expect(mapped.isPartialSuccess, isTrue);
      expect(mapped.data, equals('5'));
      expect(mapped.errors, equals([error]));
    });

    test('does not map failed result', () {
      final error = BackupError.network('Error');
      final result = BackupResult<int>.failure(error);
      final mapped = result.map((value) => value.toString());

      expect(mapped.isFailure, isTrue);
      expect(mapped.error, equals(error));
    });

    test('flatMaps success result', () {
      const result = BackupResult.success(5);
      final flatMapped = result.flatMap((value) => BackupResult.success(value * 2));

      expect(flatMapped.isSuccess, isTrue);
      expect(flatMapped.data, equals(10));
    });

    test('propagates errors in flatMap', () {
      final error1 = BackupError.network('Error 1');
      final error2 = BackupError.fileOperation('Error 2');
      final result = BackupResult.partialSuccess(5, [error1]);
      final flatMapped = result.flatMap((value) => BackupResult.partialSuccess(value * 2, [error2]));

      expect(flatMapped.isPartialSuccess, isTrue);
      expect(flatMapped.data, equals(10));
      expect(flatMapped.errors, containsAll([error1, error2]));
    });

    test('adds errors to success result', () {
      const result = BackupResult.success('data');
      final error = BackupError.network('Error');
      final withErrors = result.addErrors([error]);

      expect(withErrors.isPartialSuccess, isTrue);
      expect(withErrors.data, equals('data'));
      expect(withErrors.errors, equals([error]));
    });

    test('does not add empty errors list', () {
      const result = BackupResult.success('data');
      final withErrors = result.addErrors([]);

      expect(withErrors.isSuccess, isTrue);
      expect(withErrors, equals(result));
    });
  });

  group('BackupError', () {
    test('creates from exception', () {
      const exception = NetworkException('Network failed', context: 'test');
      final error = BackupError.fromException(exception);

      expect(error.type, equals(BackupErrorType.network));
      expect(error.message, equals('Network failed'));
      expect(error.context, equals('test'));
      expect(error.isRetryable, isTrue);
    });

    test('creates from AuthException with metadata', () {
      const exception = AuthException('Auth failed', AuthExceptionType.tokenExpired);
      final error = BackupError.fromException(exception);

      expect(error.type, equals(BackupErrorType.authentication));
      expect(error.metadata?['authType'], equals('tokenExpired'));
    });

    test('creates convenience constructors', () {
      final networkError = BackupError.network('Network failed');
      expect(networkError.type, equals(BackupErrorType.network));
      expect(networkError.isRetryable, isTrue);

      final authError = BackupError.authentication('Auth failed');
      expect(authError.type, equals(BackupErrorType.authentication));
      expect(authError.isRetryable, isFalse);

      final quotaError = BackupError.quota('Quota exceeded');
      expect(quotaError.type, equals(BackupErrorType.quota));
      expect(quotaError.isRetryable, isFalse);

      final fileError = BackupError.fileOperation('File failed');
      expect(fileError.type, equals(BackupErrorType.fileOperation));
      expect(fileError.isRetryable, isTrue);

      final serviceError = BackupError.service('Service failed');
      expect(serviceError.type, equals(BackupErrorType.service));
      expect(serviceError.isRetryable, isFalse);

      final unknownError = BackupError.unknown('Unknown failed');
      expect(unknownError.type, equals(BackupErrorType.unknown));
      expect(unknownError.isRetryable, isTrue);
    });

    test('supports equality', () {
      final error1 = BackupError.network('Network error', context: 'test');
      final error2 = BackupError.network('Network error', context: 'test');
      final error3 = BackupError.network('Different error', context: 'test');

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });

    test('has proper string representation', () {
      final error = BackupError.network('Network error', context: 'test_operation');
      expect(error.toString(), equals('BackupError(network: Network error (test_operation))'));
    });
  });
}
