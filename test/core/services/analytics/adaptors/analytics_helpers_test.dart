import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/analytics/adaptors/none_analytics_event_adaptor.dart';

// Test via a concrete subclass (NoneAnalyticsEventAdaptor) since the helpers
// are non-abstract methods on the abstract base.
void main() {
  late NoneAnalyticsEventAdaptor adaptor;

  setUp(() => adaptor = NoneAnalyticsEventAdaptor());

  group('sanitizeEventName', () {
    test('returns the name unchanged for valid input', () {
      expect(adaptor.sanitizeEventName('sync_backup'), equals('sync_backup'));
      expect(adaptor.sanitizeEventName('a'), equals('a'));
    });

    test('asserts fail for reserved firebase_ prefix', () {
      expect(() => adaptor.sanitizeEventName('firebase_event'), throwsA(isA<AssertionError>()));
    });

    test('asserts fail for reserved google_ prefix', () {
      expect(() => adaptor.sanitizeEventName('google_event'), throwsA(isA<AssertionError>()));
    });

    test('asserts fail for reserved ga_ prefix', () {
      expect(() => adaptor.sanitizeEventName('ga_event'), throwsA(isA<AssertionError>()));
    });

    test('asserts fail for name longer than 40 characters', () {
      final longName = 'a' * 41;
      expect(() => adaptor.sanitizeEventName(longName), throwsA(isA<AssertionError>()));
    });

    test('accepts name of exactly 40 characters', () {
      final name = 'a' * 40;
      expect(adaptor.sanitizeEventName(name), equals(name));
    });
  });

  group('sanitizeParameters', () {
    test('filters out null values', () {
      final result = adaptor.sanitizeParameters({'key': 'value', 'missing': null});
      expect(result, equals({'key': 'value'}));
    });

    test('returns null when all values are null', () {
      final result = adaptor.sanitizeParameters({'a': null, 'b': null});
      expect(result, isNull);
    });

    test('returns null for empty map', () {
      final result = adaptor.sanitizeParameters({});
      expect(result, isNull);
    });

    test('coerces numeric strings to num', () {
      final result = adaptor.sanitizeParameters({'count': '42', 'ratio': '3.14'});
      expect(result?['count'], equals(42));
      expect(result?['ratio'], equals(3.14));
    });

    test('keeps non-numeric strings as String', () {
      final result = adaptor.sanitizeParameters({'name': 'hello'});
      expect(result?['name'], equals('hello'));
    });

    test('mixed numeric and string values', () {
      final result = adaptor.sanitizeParameters({'count': '10', 'label': 'abc', 'skip': null});
      expect(result, equals({'count': 10, 'label': 'abc'}));
    });
  });
}
