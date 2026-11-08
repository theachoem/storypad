import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/map/place_selection_service.dart';

void main() {
  const double lat = 11.5564;
  const double lng = 104.9282;

  PlaceDbModel spot({String? placeName, String? locality, String? country, String? address}) {
    return PlaceDbModel(
      latitude: lat,
      longitude: lng,
      placeName: placeName,
      locality: locality,
      country: country,
      address: address,
    );
  }

  group('PlaceSelectionService.needsDetails', () {
    test('is false without a place', () {
      expect(PlaceSelectionService.needsDetails(null), isFalse);
    });

    test('is true while the locality is missing or blank', () {
      expect(PlaceSelectionService.needsDetails(spot()), isTrue);
      expect(PlaceSelectionService.needsDetails(spot(placeName: 'Home')), isTrue);
      expect(PlaceSelectionService.needsDetails(spot(locality: '  ')), isTrue);
    });

    test('is false once the locality is known', () {
      expect(PlaceSelectionService.needsDetails(spot(locality: 'Phnom Penh')), isFalse);
    });
  });

  group('PlaceSelectionService.mergeDetails', () {
    final geocoded = spot(placeName: 'Wat Phnom', locality: 'Phnom Penh', country: 'Cambodia', address: 'St 94');
    final saved = spot(placeName: "Grandma's");

    test('is null when neither lookup found anything', () {
      expect(PlaceSelectionService.mergeDetails(spot()), isNull);
    });

    test("takes the geocoder's details and name for an unnamed spot", () {
      final result = PlaceSelectionService.mergeDetails(spot(), geocoded: geocoded)!;
      expect(result.placeName, 'Wat Phnom');
      expect(result.locality, 'Phnom Penh');
      expect(result.country, 'Cambodia');
      expect(result.address, 'St 94');
    });

    test("the user's own name for a nearby place beats the geocoder's", () {
      final result = PlaceSelectionService.mergeDetails(spot(), saved: saved, geocoded: geocoded)!;
      expect(result.placeName, "Grandma's");
      expect(result.locality, 'Phnom Penh');
    });

    test("the spot's own name beats both", () {
      final result = PlaceSelectionService.mergeDetails(
        spot(placeName: ' Home '),
        saved: saved,
        geocoded: geocoded,
      )!;
      expect(result.placeName, 'Home');
      expect(result.locality, 'Phnom Penh');
    });

    test('a blank own name counts as none', () {
      final result = PlaceSelectionService.mergeDetails(
        spot(placeName: '   '),
        saved: saved,
        geocoded: geocoded,
      )!;
      expect(result.placeName, "Grandma's");
    });

    test('only a saved name found (geocoder offline): names the spot, nothing else', () {
      final result = PlaceSelectionService.mergeDetails(spot(), saved: saved)!;
      expect(result.placeName, "Grandma's");
      expect(result.locality, isNull);
    });

    test('a geocoded place without a name leaves the spot unnamed', () {
      final result = PlaceSelectionService.mergeDetails(spot(), geocoded: spot(locality: 'Phnom Penh'))!;
      expect(result.placeName, isNull);
      expect(result.locality, 'Phnom Penh');
    });

    // The pin is where the user put it: a geocoder answering for a nearby point must not move it.
    test("stays at the spot's own coordinates", () {
      final elsewhere = PlaceDbModel(latitude: lat + 0.01, longitude: lng - 0.01, locality: 'Phnom Penh');
      final result = PlaceSelectionService.mergeDetails(spot(), geocoded: elsewhere)!;
      expect(result.latLng, const SpLatLng(lat, lng));
    });
  });

  group('PlaceSelectionService.isSameSpot', () {
    const base = SpLatLng(lat, lng);

    test('is true for the same point and within ~11m', () {
      expect(PlaceSelectionService.isSameSpot(base, base), isTrue);
      expect(PlaceSelectionService.isSameSpot(base, const SpLatLng(lat + 0.00005, lng - 0.00005)), isTrue);
    });

    test('is false once either axis is ~11m or more apart', () {
      expect(PlaceSelectionService.isSameSpot(base, const SpLatLng(lat + 0.0002, lng)), isFalse);
      expect(PlaceSelectionService.isSameSpot(base, const SpLatLng(lat, lng - 0.0002)), isFalse);
    });
  });

  group('PlaceSelectionService.hasChanges', () {
    final saved = spot(placeName: 'Home', locality: 'Phnom Penh', country: 'Cambodia', address: 'St 94');

    test('anything is a change when the story has no place yet', () {
      expect(PlaceSelectionService.hasChanges(spot(), null), isTrue);
    });

    test('the same place is no change', () {
      expect(PlaceSelectionService.hasChanges(saved.copyWith(), saved), isFalse);
    });

    test('ignores surrounding spaces, and blank vs missing', () {
      final selected = spot(placeName: ' Home ', locality: 'Phnom Penh ', country: 'Cambodia', address: 'St 94');
      expect(PlaceSelectionService.hasChanges(selected, saved), isFalse);
      expect(PlaceSelectionService.hasChanges(spot(placeName: ''), spot(address: '  ')), isFalse);
    });

    test('a moved spot is a change', () {
      expect(PlaceSelectionService.hasChanges(saved.copyWith(latitude: lat + 0.001), saved), isTrue);
      expect(PlaceSelectionService.hasChanges(saved.copyWith(longitude: lng + 0.001), saved), isTrue);
    });

    test('a renamed or re-detailed place is a change', () {
      expect(PlaceSelectionService.hasChanges(saved.copyWith(placeName: 'Office'), saved), isTrue);
      expect(PlaceSelectionService.hasChanges(saved.copyWith(placeName: null), saved), isTrue);
      expect(PlaceSelectionService.hasChanges(saved.copyWith(locality: 'Siem Reap'), saved), isTrue);
      expect(PlaceSelectionService.hasChanges(saved.copyWith(country: 'Thailand'), saved), isTrue);
      expect(PlaceSelectionService.hasChanges(saved.copyWith(address: 'St 1'), saved), isTrue);
    });
  });
}
