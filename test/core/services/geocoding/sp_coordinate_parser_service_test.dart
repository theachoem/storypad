import 'package:flutter_test/flutter_test.dart';
import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_coordinate_parser_service.dart';

void main() {
  // Phnom Penh — used as a reference city for short Plus Code tests.
  const olc.LatLng phnomPenhOlc = olc.LatLng(11.5564, 104.9282);
  const SpLatLng phnomPenhSp = SpLatLng(11.5564, 104.9282);

  Future<SpLatLng?> phnomPenhResolver(String _) async => phnomPenhSp;

  // ---------------------------------------------------------------------------
  // Decimal
  // ---------------------------------------------------------------------------

  group('SpCoordinateParserService — decimal', () {
    test('parses with space after comma', () async {
      final result = await SpCoordinateParserService.parse('11.591237, 104.87499');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.591237, 1e-6));
      expect(result.longitude, closeTo(104.87499, 1e-6));
    });

    test('parses without space after comma', () async {
      final result = await SpCoordinateParserService.parse('11.591237330838586,104.87499653591452');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.591237330838586, 1e-9));
      expect(result.longitude, closeTo(104.87499653591452, 1e-9));
    });

    test('parses negative coordinates', () async {
      final result = await SpCoordinateParserService.parse('-33.8688, 151.2093');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(-33.8688, 1e-4));
      expect(result.longitude, closeTo(151.2093, 1e-4));
    });

    test('returns null when latitude is out of range', () async {
      expect(await SpCoordinateParserService.parse('91.0, 0.0'), isNull);
      expect(await SpCoordinateParserService.parse('-91.0, 0.0'), isNull);
    });

    test('returns null when longitude is out of range', () async {
      expect(await SpCoordinateParserService.parse('0.0, 181.0'), isNull);
      expect(await SpCoordinateParserService.parse('0.0, -181.0'), isNull);
    });

    test('returns null for non-numeric values', () async {
      expect(await SpCoordinateParserService.parse('abc, def'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Cardinal
  // ---------------------------------------------------------------------------

  group('SpCoordinateParserService — cardinal', () {
    test('parses N, E with degree symbol', () async {
      final result = await SpCoordinateParserService.parse('11.57934° N, 104.87423° E');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.57934, 1e-5));
      expect(result.longitude, closeTo(104.87423, 1e-5));
    });

    test('parses N, E without degree symbol', () async {
      final result = await SpCoordinateParserService.parse('11.57934 N, 104.87423 E');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.57934, 1e-5));
      expect(result.longitude, closeTo(104.87423, 1e-5));
    });

    test('parses N, E without spaces around degree symbol', () async {
      final result = await SpCoordinateParserService.parse('11.57934°N, 104.87423°E');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.57934, 1e-5));
      expect(result.longitude, closeTo(104.87423, 1e-5));
    });

    test('parses S, W and negates both values', () async {
      final result = await SpCoordinateParserService.parse('11.57934° S, 104.87423° W');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(-11.57934, 1e-5));
      expect(result.longitude, closeTo(-104.87423, 1e-5));
    });

    test('parses reversed order: E, N', () async {
      final result = await SpCoordinateParserService.parse('104.87423° E, 11.57934° N');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.57934, 1e-5));
      expect(result.longitude, closeTo(104.87423, 1e-5));
    });

    test('parses lowercase cardinal letters', () async {
      final result = await SpCoordinateParserService.parse('11.57934°n, 104.87423°e');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.57934, 1e-5));
      expect(result.longitude, closeTo(104.87423, 1e-5));
    });
  });

  // ---------------------------------------------------------------------------
  // Plus Code — full
  // ---------------------------------------------------------------------------

  group('SpCoordinateParserService — full Plus Code', () {
    test('decodes a known full Plus Code', () async {
      // Encode a known location, then verify the service round-trips it.
      const olc.LatLng original = olc.LatLng(11.5564, 104.9282);
      final String code = olc.PlusCode.encode(original).toString();

      final result = await SpCoordinateParserService.parse(code);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(original.latitude, 0.01));
      expect(result.longitude, closeTo(original.longitude, 0.01));
    });

    test('decodes a full Plus Code in lowercase', () async {
      const olc.LatLng original = olc.LatLng(48.8566, 2.3522);
      final String code = olc.PlusCode.encode(original).toString().toLowerCase();

      final result = await SpCoordinateParserService.parse(code);
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(original.latitude, 0.01));
      expect(result.longitude, closeTo(original.longitude, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Plus Code — short
  // ---------------------------------------------------------------------------

  group('SpCoordinateParserService — short Plus Code', () {
    test('recovers short Plus Code with city hint via injected resolver', () async {
      // Generate a short code relative to Phnom Penh.
      final String fullCode = olc.PlusCode.encode(phnomPenhOlc).toString();
      final String shortCode = olc.PlusCode(fullCode).shorten(phnomPenhOlc).toString();

      final result = await SpCoordinateParserService.parse(
        '$shortCode Phnom Penh',
        referenceResolver: phnomPenhResolver,
      );

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(phnomPenhSp.latitude, 0.1));
      expect(result.longitude, closeTo(phnomPenhSp.longitude, 0.1));
    });

    test('returns null for short Plus Code without any city hint', () async {
      final String fullCode = olc.PlusCode.encode(phnomPenhOlc).toString();
      final String shortCode = olc.PlusCode(fullCode).shorten(phnomPenhOlc).toString();

      final result = await SpCoordinateParserService.parse(shortCode);
      expect(result, isNull);
    });

    test('returns null when reference resolver returns null', () async {
      final String fullCode = olc.PlusCode.encode(phnomPenhOlc).toString();
      final String shortCode = olc.PlusCode(fullCode).shorten(phnomPenhOlc).toString();

      final result = await SpCoordinateParserService.parse(
        '$shortCode Unknown City',
        referenceResolver: (_) async => null,
      );
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  group('SpCoordinateParserService — edge cases', () {
    test('returns null for empty string', () async {
      expect(await SpCoordinateParserService.parse(''), isNull);
    });

    test('returns null for whitespace-only string', () async {
      expect(await SpCoordinateParserService.parse('   '), isNull);
    });

    test('returns null for completely unrecognised input', () async {
      expect(await SpCoordinateParserService.parse('Phnom Penh'), isNull);
      expect(await SpCoordinateParserService.parse('hello world'), isNull);
    });

    test('trims surrounding whitespace before parsing', () async {
      final result = await SpCoordinateParserService.parse('  11.5564 ,  104.9282  ');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(11.5564, 1e-4));
      expect(result.longitude, closeTo(104.9282, 1e-4));
    });
  });
}
