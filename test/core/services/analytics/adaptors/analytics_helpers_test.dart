import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/analytics/adaptors/none_analytics_event_adaptor.dart';
import 'package:storypad/core/types/path_type.dart';

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

  group('urlAnalyticParameters', () {
    test('names only our own domain, never path, query or fragment', () {
      expect(
        adaptor.urlAnalyticParameters('https://storypad.me/privacy-policy?x=1#top'),
        equals({'host': 'storypad.me'}),
      );
      expect(
        adaptor.urlAnalyticParameters('https://static.storypad.me/a.json'),
        equals({'host': 'static.storypad.me'}),
      );
    });

    test('sends nothing for any other site', () {
      expect(adaptor.urlAnalyticParameters('https://example.com/private/path?q=secret#frag'), isNull);
      expect(adaptor.urlAnalyticParameters('https://notstorypad.me/'), isNull);
      expect(adaptor.urlAnalyticParameters('https://storypad.me.evil.com/'), isNull);
    });

    test('sends nothing for map links, so no coordinates', () {
      expect(adaptor.urlAnalyticParameters('https://maps.apple.com/?ll=11.5564,104.9282'), isNull);
      expect(adaptor.urlAnalyticParameters('https://www.google.com/maps/search/?api=1&query=11.5564,104.9282'), isNull);
    });

    test('sends nothing for a Reddit share link, so no story text', () {
      expect(
        adaptor.urlAnalyticParameters(
          'https://www.reddit.com/submit?title=My%20day&text=Dear%20diary%2C%20today%20I...',
        ),
        isNull,
      );
    });

    test('sends nothing for mailto or app links, not even the scheme', () {
      expect(adaptor.urlAnalyticParameters('mailto:someone@example.com'), isNull);
      expect(adaptor.urlAnalyticParameters('someapp://open/profile/123'), isNull);
    });

    test('returns null for an unparseable url', () {
      expect(adaptor.urlAnalyticParameters('http://[::1'), isNull);
    });
  });

  group('storyAnalyticParameters', () {
    final DateTime date = DateTime(2024, 2, 14);

    final StoryDbModel story = StoryDbModel(
      id: 1,
      type: PathType.docs,
      year: date.year,
      month: date.month,
      day: date.day,
      hour: 9,
      minute: 30,
      second: 0,
      starred: true,
      pinned: false,
      feeling: null,
      tags: const ['1', '2'],
      assets: null,
      place: PlaceDbModel(latitude: 11.56, longitude: 104.92, placeName: 'Home', country: 'Cambodia'),
      latestContent: StoryContentDbModel(
        id: 2,
        title: 'Private title',
        plainText: 'Private text',
        createdAt: date,
        richPages: [
          StoryPageDbModel.legacy(
            id: 3,
            title: 'Private title',
            body: [
              {'insert': 'Private text\n'},
            ],
            wordCount: 2,
          ),
        ],
      ),
      draftContent: null,
      createdAt: date,
      updatedAt: date,
      movedToBinAt: null,
      galleryTemplateId: null,
      templateId: null,
      event: null,
      lastSavedDeviceId: 'test-device',
      permanentlyDeletedAt: null,
    );

    test('sends counts, flags and categories', () {
      final params = adaptor.storyAnalyticParameters(story, peopleTagsCount: 1)!;

      expect(params['type'], 'docs');
      expect(params['starred'], 'true');
      expect(params['pages_count'], 1);
      expect(params['tags_count'], 2);
      expect(params['people_tags_count'], 1);
    });

    test("never sends the entry's date, text or location", () {
      final params = adaptor.storyAnalyticParameters(story)!;

      for (final key in ['year', 'month', 'day', 'hour', 'title', 'place', 'latitude', 'longitude']) {
        expect(params.containsKey(key), isFalse, reason: key);
      }

      final values = params.values.map((v) => v.toString()).join(' ');
      for (final secret in ['Private', 'Home', 'Cambodia', '11.56', '104.92', '2024']) {
        expect(values, isNot(contains(secret)), reason: secret);
      }
    });
  });
}
