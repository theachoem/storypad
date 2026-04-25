import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/remote_config/adaptors/none_remote_config_adaptor.dart';

void main() {
  late NoneRemoteConfigAdaptor adaptor;

  setUp(() => adaptor = NoneRemoteConfigAdaptor());

  group('NoneRemoteConfigAdaptor', () {
    test('initialize completes without throwing', () async {
      await expectLater(
        adaptor.initialize({'feature_enabled': false, 'api_url': 'https://example.com'}),
        completes,
      );
    });

    test('getBool returns defaultValue', () {
      expect(adaptor.getBool('feature_x', true), isTrue);
      expect(adaptor.getBool('feature_x', false), isFalse);
    });

    test('getString returns defaultValue', () {
      expect(adaptor.getString('api_url', 'https://fallback.com'), equals('https://fallback.com'));
      expect(adaptor.getString('empty_key', ''), equals(''));
    });

    test('getInt returns defaultValue', () {
      expect(adaptor.getInt('max_retries', 3), equals(3));
      expect(adaptor.getInt('timeout', 0), equals(0));
    });

    test('getDouble returns defaultValue', () {
      expect(adaptor.getDouble('ratio', 1.5), equals(1.5));
    });

    test('getJsonString returns defaultValue', () {
      expect(adaptor.getJsonString('config_json', '{}'), equals('{}'));
    });

    test('onConfigUpdated emits no events', () async {
      final events = await adaptor.onConfigUpdated.toList().timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => [],
      );
      expect(events, isEmpty);
    });
  });
}
