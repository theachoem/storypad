import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/widgets/maps/map_types.dart';

void main() {
  group('SpMapRenderer.googleMapsUnavailableIn', () {
    test('matches every mainland China timezone, including legacy aliases', () {
      for (final timezone in [
        'Asia/Shanghai',
        'Asia/Urumqi',
        'Asia/Chongqing',
        'Asia/Chungking',
        'Asia/Harbin',
        'Asia/Kashgar',
        'PRC',
      ]) {
        expect(SpMapRenderer.googleMapsUnavailableIn(timezone), isTrue, reason: timezone);
      }
    });

    // These are Chinese-speaking regions where Google Maps works normally, and
    // are the mistake most likely to be made when editing the timezone list.
    test('does not match Hong Kong, Macau or Taipei', () {
      for (final timezone in ['Asia/Hong_Kong', 'Asia/Macau', 'Asia/Taipei']) {
        expect(SpMapRenderer.googleMapsUnavailableIn(timezone), isFalse, reason: timezone);
      }
    });

    test('does not match unrelated timezones', () {
      for (final timezone in ['Asia/Phnom_Penh', 'Europe/Berlin', 'America/New_York', 'UTC']) {
        expect(SpMapRenderer.googleMapsUnavailableIn(timezone), isFalse, reason: timezone);
      }
    });

    // A device that won't report its timezone must not be treated as China.
    test('does not match when the timezone is unknown', () {
      expect(SpMapRenderer.googleMapsUnavailableIn(null), isFalse);
      expect(SpMapRenderer.googleMapsUnavailableIn(''), isFalse);
    });
  });
}
