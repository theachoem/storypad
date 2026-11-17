import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';

void main() {
  PlaceDbModel place({String? locality, String? country}) {
    return PlaceDbModel(latitude: 11.556412, longitude: 104.928213, locality: locality, country: country);
  }

  group('PlaceDbModel.areaLabel', () {
    test('joins locality and country', () {
      expect(place(locality: 'Phnom Penh', country: 'Cambodia').areaLabel, 'Phnom Penh, Cambodia');
    });

    test('shows whichever one is known', () {
      expect(place(locality: 'Phnom Penh').areaLabel, 'Phnom Penh');
      expect(place(country: 'Cambodia').areaLabel, 'Cambodia');
    });

    test('trims, and treats blank as unknown', () {
      expect(place(locality: '  Phnom Penh ', country: '   ').areaLabel, 'Phnom Penh');
      expect(place(locality: '', country: ' Cambodia').areaLabel, 'Cambodia');
    });

    test('is null when neither is known', () {
      expect(place().areaLabel, isNull);
      expect(place(locality: ' ', country: '').areaLabel, isNull);
    });
  });

  group('PlaceDbModel.areaOrCoordinatesLabel', () {
    test('is the area when known', () {
      expect(place(locality: 'Phnom Penh', country: 'Cambodia').areaOrCoordinatesLabel, 'Phnom Penh, Cambodia');
    });

    test('falls back to coordinates with 5 decimals', () {
      expect(place().areaOrCoordinatesLabel, '11.55641, 104.92821');
      expect(place(locality: '  ').areaOrCoordinatesLabel, '11.55641, 104.92821');
    });
  });
}
