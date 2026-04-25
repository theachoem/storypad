import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/analytics/adaptors/none_analytics_user_property_adaptor.dart';

void main() {
  late NoneAnalyticsUserPropertyAdaptor adaptor;

  setUp(() => adaptor = NoneAnalyticsUserPropertyAdaptor());

  group('NoneAnalyticsUserPropertyAdaptor', () {
    test('setUserProperty completes without throwing', () async {
      await expectLater(adaptor.setUserProperty('theme_mode', 'dark'), completes);
    });

    test('setUserProperty with null value completes without throwing', () async {
      await expectLater(adaptor.setUserProperty('font_family', null), completes);
    });

    test('logSetThemeMode completes without throwing', () async {
      await expectLater(
        adaptor.logSetThemeMode(newThemeMode: .dark),
        completes,
      );
    });

    test('logSetFontFamily completes without throwing', () async {
      await expectLater(adaptor.logSetFontFamily(newFontFamily: 'Roboto'), completes);
    });

    test('logSetStoryTilePreferences completes without throwing', () async {
      await expectLater(
        adaptor.logSetStoryTilePreferences(
          showTime: true,
          showPageCount: false,
          showTagLabels: true,
          showVoiceCount: false,
          displayCharacterCount: 100,
        ),
        completes,
      );
    });
  });
}
