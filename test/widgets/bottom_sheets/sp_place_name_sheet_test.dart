import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/widgets/bottom_sheets/sp_place_name_sheet.dart';

void main() {
  const from = SpLatLng(11.5564, 104.9282);

  PlaceDbModel named(String? name, double latitude, double longitude, {String? locality}) {
    return PlaceDbModel(latitude: latitude, longitude: longitude, placeName: name, locality: locality);
  }

  group('SpPlaceNameSheet.groupNamedPlaces', () {
    test('skips places without a name', () {
      final result = SpPlaceNameSheet.groupNamedPlaces([
        named(null, 11.5564, 104.9282),
        named('', 11.5564, 104.9282),
        named('   ', 11.5564, 104.9282),
      ], from);
      expect(result, isEmpty);
    });

    test('one row per name and spot: case, spaces and a few meters apart merge into the first', () {
      final first = named('Home', 11.55641, 104.92821, locality: 'Phnom Penh');
      final result = SpPlaceNameSheet.groupNamedPlaces([
        first,
        named('home', 11.55642, 104.92822),
        named(' HOME ', 11.55643, 104.92823),
      ], from);

      expect(result, hasLength(1));
      expect(result.single.place, same(first));
    });

    test('the same name far apart, or another name at the same spot, are separate rows', () {
      final result = SpPlaceNameSheet.groupNamedPlaces([
        named('Home', 11.5564, 104.9282),
        named('Home', 13.3633, 103.8564),
        named('Office', 11.5564, 104.9282),
      ], from);

      expect(result.map((e) => e.place.placeName), unorderedEquals(['Home', 'Home', 'Office']));
    });

    test('a place right at 0° is still one row', () {
      final result = SpPlaceNameSheet.groupNamedPlaces([
        named('Null Island', 0.0001, -0.0001),
        named('Null Island', -0.0001, 0.0001),
      ], from);
      expect(result, hasLength(1));
    });

    test('nearest first, with the distance from the spot being named', () {
      final siemReap = named('Angkor', 13.3633, 103.8564);
      final nearby = named('Cafe', 11.5600, 104.9282);
      final here = named('Home', 11.5564, 104.9282);

      final result = SpPlaceNameSheet.groupNamedPlaces([siemReap, nearby, here], from);

      expect(result.map((e) => e.place), [here, nearby, siemReap]);
      expect(result[0].distance, 0);
      expect(result[1].distance, closeTo(400, 5));
      expect(result[2].distance, closeTo(232000, 3000));
    });
  });

  group('SpPlaceNameSheet.formatDistance', () {
    test('meters under 1 km', () {
      expect(SpPlaceNameSheet.formatDistance(0), '0 m');
      expect(SpPlaceNameSheet.formatDistance(12.4), '12 m');
      expect(SpPlaceNameSheet.formatDistance(999.4), '999 m');
    });

    test('rounds to km before it would show "1000 m"', () {
      expect(SpPlaceNameSheet.formatDistance(999.6), '1.0 km');
    });

    test('one decimal of km under 10 km', () {
      expect(SpPlaceNameSheet.formatDistance(1000), '1.0 km');
      expect(SpPlaceNameSheet.formatDistance(1260), '1.3 km');
      expect(SpPlaceNameSheet.formatDistance(9940), '9.9 km');
    });

    test('whole km from 10 km', () {
      expect(SpPlaceNameSheet.formatDistance(9960), '10 km');
      expect(SpPlaceNameSheet.formatDistance(10000), '10 km');
      expect(SpPlaceNameSheet.formatDistance(232400), '232 km');
    });
  });
}
