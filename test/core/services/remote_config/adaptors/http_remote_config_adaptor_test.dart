// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/services/remote_config/adaptors/http_remote_config_adaptor.dart';

HttpRemoteConfigAdaptor _adaptorWith(http.Client client) {
  return HttpRemoteConfigAdaptor(baseUrl: 'https://cdn.example.com', httpClient: client);
}

void main() {
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    await RemoteConfigCacheStorage().remove();
  });

  group('HttpRemoteConfigAdaptor', () {
    test('applies fetched values after the background refetch resolves', () async {
      final adaptor = _adaptorWith(
        MockClient((_) async => http.Response(jsonEncode({'SURVEY_URL': 'https://example.com/survey'}), 200)),
      );

      await adaptor.initialize({'SURVEY_URL': ''});
      await pumpEventQueue();

      expect(adaptor.getString('SURVEY_URL', ''), 'https://example.com/survey');
    });

    test('falls back to defaults when the fetch fails', () async {
      final adaptor = _adaptorWith(MockClient((_) async => throw Exception('Network error')));

      await adaptor.initialize({'SURVEY_URL': 'default-url'});
      await pumpEventQueue();

      expect(adaptor.getString('SURVEY_URL', ''), 'default-url');
    });

    test('falls back to defaults on a non-200 response', () async {
      final adaptor = _adaptorWith(MockClient((_) async => http.Response('Not Found', 404)));

      await adaptor.initialize({'SURVEY_URL': 'default-url'});
      await pumpEventQueue();

      expect(adaptor.getString('SURVEY_URL', ''), 'default-url');
    });

    test('uses the disk cache immediately, before any network round trip', () async {
      await RemoteConfigCacheStorage().writeMap({'SURVEY_URL': 'cached-url'});

      final completer = Completer<http.Response>();
      final adaptor = _adaptorWith(MockClient((_) => completer.future));

      await adaptor.initialize({'SURVEY_URL': 'default-url'});

      expect(adaptor.getString('SURVEY_URL', ''), 'cached-url');
    });

    test('persists a successful fetch to the disk cache', () async {
      final adaptor = _adaptorWith(
        MockClient((_) async => http.Response(jsonEncode({'SURVEY_URL': 'https://example.com/survey'}), 200)),
      );

      await adaptor.initialize({'SURVEY_URL': ''});
      await pumpEventQueue();

      final cached = await RemoteConfigCacheStorage().readMap();
      expect(cached?['SURVEY_URL'], 'https://example.com/survey');
    });

    test('getJsonString re-encodes a fetched nested object', () async {
      final adaptor = _adaptorWith(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'FEATURE_FLAGS': {'foo': true},
            }),
            200,
          ),
        ),
      );

      await adaptor.initialize({'FEATURE_FLAGS': jsonEncode({})});
      await pumpEventQueue();

      expect(jsonDecode(adaptor.getJsonString('FEATURE_FLAGS', '{}')), {'foo': true});
    });

    test('onConfigUpdated emits the fetched keys after a successful refetch', () async {
      final adaptor = _adaptorWith(
        MockClient((_) async => http.Response(jsonEncode({'SURVEY_URL': 'https://example.com/survey'}), 200)),
      );

      final updates = adaptor.onConfigUpdated.first;
      await adaptor.initialize({'SURVEY_URL': ''});

      expect(await updates, contains('SURVEY_URL'));
    });

    test('getBool/getInt/getDouble coerce string values and fall back to defaults otherwise', () async {
      final adaptor = _adaptorWith(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'BOOL_KEY': 'true', 'INT_KEY': '42', 'DOUBLE_KEY': '1.5', 'UNRELATED': 'x'}),
            200,
          ),
        ),
      );

      await adaptor.initialize({});
      await pumpEventQueue();

      expect(adaptor.getBool('BOOL_KEY', false), true);
      expect(adaptor.getInt('INT_KEY', 0), 42);
      expect(adaptor.getDouble('DOUBLE_KEY', 0), 1.5);
      expect(adaptor.getBool('MISSING_KEY', true), true);
    });
  });
}
