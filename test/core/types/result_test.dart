import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/types/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('creates success result with value', () {
        const result = Result<String, int>.success('test');
        
        expect(result.isSuccess, isTrue);
        expect(result.isError, isFalse);
        expect(result.value, equals('test'));
      });

      test('throws when accessing error on success', () {
        const result = Result<String, int>.success('test');
        
        expect(() => result.error, throwsStateError);
      });

      test('equality works correctly', () {
        const result1 = Result<String, int>.success('test');
        const result2 = Result<String, int>.success('test');
        const result3 = Result<String, int>.success('different');
        
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString returns formatted string', () {
        const result = Result<String, int>.success('test');
        
        expect(result.toString(), equals('Success(test)'));
      });
    });

    group('Error', () {
      test('creates error result with error value', () {
        const result = Result<String, int>.error(404);
        
        expect(result.isSuccess, isFalse);
        expect(result.isError, isTrue);
        expect(result.error, equals(404));
      });

      test('throws when accessing value on error', () {
        const result = Result<String, int>.error(404);
        
        expect(() => result.value, throwsStateError);
      });

      test('equality works correctly', () {
        const result1 = Result<String, int>.error(404);
        const result2 = Result<String, int>.error(404);
        const result3 = Result<String, int>.error(500);
        
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('toString returns formatted string', () {
        const result = Result<String, int>.error(404);
        
        expect(result.toString(), equals('Error(404)'));
      });
    });

    group('fold', () {
      test('calls success function for success result', () {
        const result = Result<String, int>.success('test');
        
        final folded = result.fold(
          success: (value) => 'Success: $value',
          error: (error) => 'Error: $error',
        );
        
        expect(folded, equals('Success: test'));
      });

      test('calls error function for error result', () {
        const result = Result<String, int>.error(404);
        
        final folded = result.fold(
          success: (value) => 'Success: $value',
          error: (error) => 'Error: $error',
        );
        
        expect(folded, equals('Error: 404'));
      });
    });

    group('map', () {
      test('transforms success value', () {
        const result = Result<String, int>.success('test');
        
        final mapped = result.map((value) => value.length);
        
        expect(mapped.isSuccess, isTrue);
        expect(mapped.value, equals(4));
      });

      test('passes through error unchanged', () {
        const result = Result<String, int>.error(404);
        
        final mapped = result.map((value) => value.length);
        
        expect(mapped.isError, isTrue);
        expect(mapped.error, equals(404));
      });
    });

    group('mapError', () {
      test('transforms error value', () {
        const result = Result<String, int>.error(404);
        
        final mapped = result.mapError((error) => 'HTTP $error');
        
        expect(mapped.isError, isTrue);
        expect(mapped.error, equals('HTTP 404'));
      });

      test('passes through success unchanged', () {
        const result = Result<String, int>.success('test');
        
        final mapped = result.mapError((error) => 'HTTP $error');
        
        expect(mapped.isSuccess, isTrue);
        expect(mapped.value, equals('test'));
      });
    });

    group('flatMap', () {
      test('chains successful operations', () {
        const result = Result<String, String>.success('test');
        
        final chained = result.flatMap((value) =>
            Result<int, String>.success(value.length));
        
        expect(chained.isSuccess, isTrue);
        expect(chained.value, equals(4));
      });

      test('chains to error result', () {
        const result = Result<String, String>.success('test');
        
        final chained = result.flatMap((value) =>
            const Result<int, String>.error('failed'));
        
        expect(chained.isError, isTrue);
        expect(chained.error, equals('failed'));
      });

      test('does not execute operation on error', () {
        const result = Result<String, String>.error('initial error');
        bool operationCalled = false;
        
        final chained = result.flatMap((value) {
          operationCalled = true;
          return Result<int, String>.success(value.length);
        });
        
        expect(operationCalled, isFalse);
        expect(chained.isError, isTrue);
        expect(chained.error, equals('initial error'));
      });
    });
  });
}