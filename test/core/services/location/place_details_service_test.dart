import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/location/place_details_service.dart';

void main() {
  const SpLatLng spot = SpLatLng(11.5564, 104.9282);
  // ~2m away: the same ~11m spot.
  const SpLatLng sameSpot = SpLatLng(11.55642, 104.92821);
  const SpLatLng otherSpot = SpLatLng(11.6000, 104.9000);

  final originalGeocode = PlaceDetailsService.reverseGeocode;
  final originalGeocodeViaDb = PlaceDetailsService.reverseGeocodeViaDb;

  late int geocodeCalls;

  void geocodeWith(Future<PlaceDbModel?> Function(SpLatLng latLng) geocode) {
    PlaceDetailsService.reverseGeocode = (latLng) {
      geocodeCalls += 1;
      return geocode(latLng);
    };
  }

  PlaceDbModel phnomPenh(SpLatLng latLng) {
    return PlaceDbModel(latitude: latLng.latitude, longitude: latLng.longitude, locality: 'Phnom Penh');
  }

  setUp(() {
    geocodeCalls = 0;
    PlaceDetailsService.reset();
    PlaceDetailsService.reverseGeocodeViaDb = (_, {double radius = 0}) async => null;
  });

  tearDown(() {
    PlaceDetailsService.reverseGeocode = originalGeocode;
    PlaceDetailsService.reverseGeocodeViaDb = originalGeocodeViaDb;
    PlaceDetailsService.reset();
  });

  group('PlaceDetailsService.geocode', () {
    test('joins a lookup still running for the same spot', () async {
      final completer = Completer<PlaceDbModel?>();
      geocodeWith((_) => completer.future);

      final first = PlaceDetailsService.geocode(spot);
      final second = PlaceDetailsService.geocode(sameSpot);
      completer.complete(phnomPenh(spot));

      expect((await first)?.locality, 'Phnom Penh');
      expect((await second)?.locality, 'Phnom Penh');
      expect(geocodeCalls, 1);
    });

    test('keeps a found place', () async {
      geocodeWith((latLng) async => phnomPenh(latLng));

      await PlaceDetailsService.geocode(spot);
      await PlaceDetailsService.geocode(sameSpot);

      expect(geocodeCalls, 1);
    });

    test('looks up another spot on its own', () async {
      geocodeWith((latLng) async => phnomPenh(latLng));

      await PlaceDetailsService.geocode(spot);
      await PlaceDetailsService.geocode(otherSpot);

      expect(geocodeCalls, 2);
    });

    test('forgets a failure, so the spot is retried (e.g. back online)', () async {
      geocodeWith((_) async => throw Exception('offline'));
      expect(await PlaceDetailsService.geocode(spot), isNull);

      geocodeWith((latLng) async => phnomPenh(latLng));
      expect((await PlaceDetailsService.geocode(spot))?.locality, 'Phnom Penh');
      expect(geocodeCalls, 2);
    });

    test('forgets a spot with nothing found', () async {
      geocodeWith((_) async => null);

      await PlaceDetailsService.geocode(spot);
      await PlaceDetailsService.geocode(spot);

      expect(geocodeCalls, 2);
    });
  });

  group('PlaceDetailsService.details', () {
    test("keeps the place's own spot and name", () async {
      geocodeWith((_) async => PlaceDbModel(latitude: 0, longitude: 0, locality: 'Phnom Penh', placeName: 'Wat'));

      final place = PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude, placeName: 'Home');
      final details = await PlaceDetailsService.details(place);

      expect(details?.latitude, spot.latitude);
      expect(details?.longitude, spot.longitude);
      expect(details?.placeName, 'Home');
      expect(details?.locality, 'Phnom Penh');
    });

    test("prefers the user's own name for a place nearby", () async {
      geocodeWith((_) async => PlaceDbModel(latitude: 0, longitude: 0, locality: 'Phnom Penh', placeName: 'Wat'));
      PlaceDetailsService.reverseGeocodeViaDb = (_, {double radius = 0}) async =>
          PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude, placeName: 'Grandma');

      final details = await PlaceDetailsService.details(
        PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude),
      );

      expect(details?.placeName, 'Grandma');
    });

    test("gives the user's own name without waiting for the geocoder", () async {
      geocodeWith((_) => Completer<PlaceDbModel?>().future);
      PlaceDetailsService.reverseGeocodeViaDb = (_, {double radius = 0}) async =>
          PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude, placeName: 'Home');

      final named = await PlaceDetailsService.savedName(
        PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude),
      );

      expect(named?.placeName, 'Home');
      expect(geocodeCalls, 0);
    });

    test('reuses a named place up to 75m from the current location, but names a spot only within 30m', () async {
      final radii = <double>[];
      PlaceDetailsService.reverseGeocodeViaDb = (_, {double radius = 0}) async {
        radii.add(radius);
        return null;
      };

      await PlaceDetailsService.savedPlaceAtCurrentLocation(spot);
      await PlaceDetailsService.savedName(PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude));

      expect(radii, [PlaceDetailsService.currentLocationRadius, PlaceDetailsService.namedPlaceRadius]);
    });

    test('is null offline with no name of the user nearby', () async {
      geocodeWith((_) async => throw Exception('offline'));

      final details = await PlaceDetailsService.details(
        PlaceDbModel(latitude: spot.latitude, longitude: spot.longitude),
      );

      expect(details, isNull);
    });
  });
}
