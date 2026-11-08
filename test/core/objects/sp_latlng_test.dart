import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/sp_latlng.dart';

void main() {
  group('SpLatLng.distanceTo', () {
    test('is 0 to itself', () {
      const point = SpLatLng(11.5564, 104.9282);
      expect(point.distanceTo(point), 0);
    });

    test('one degree of latitude is about 111 km', () {
      const a = SpLatLng(0, 0);
      const b = SpLatLng(1, 0);
      expect(a.distanceTo(b), closeTo(111195, 10));
    });

    test('is the same both ways', () {
      const phnomPenh = SpLatLng(11.5564, 104.9282);
      const siemReap = SpLatLng(13.3633, 103.8564);
      expect(phnomPenh.distanceTo(siemReap), closeTo(siemReap.distanceTo(phnomPenh), 0.001));
      expect(phnomPenh.distanceTo(siemReap), closeTo(232000, 3000));
    });

    // Nearest-first sorting must not put a place across the date line at the far end.
    test('takes the short way across the antimeridian', () {
      const west = SpLatLng(10, 179.9);
      const east = SpLatLng(10, -179.9);
      expect(west.distanceTo(east), closeTo(21900, 100));
    });

    test('is half the earth for antipodal points (no NaN)', () {
      const a = SpLatLng(11.5564, 104.9282);
      const b = SpLatLng(-11.5564, -75.0718);
      expect(a.distanceTo(b), closeTo(20015087, 1));
      expect(const SpLatLng(90, 0).distanceTo(const SpLatLng(-90, 0)), closeTo(20015087, 1));
    });
  });
}
