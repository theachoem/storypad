import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';

/// Parses a free-form coordinate string into a [SpLatLng].
///
/// Supported formats:
/// - Decimal:  `11.591237, 104.87499`  or  `11.591237,104.87499`
/// - Cardinal: `11.57934° N, 104.87423° E`  (any order, spaces / ° optional)
/// - Full Plus Code:  `7P28QRVW+62`  (decoded directly)
/// - Short Plus Code:  `X4MQ+2V Al Haram, Egypt`  or  `X4HH+QX4, Egypt`
///   (space or comma-separated, location geocoded for reference, then recovered)
///
/// Returns `null` when the input cannot be parsed or Plus Code recovery fails.
class SpCoordinateParserService {
  const SpCoordinateParserService._();

  static final _cardinalPartRegex = RegExp(r'^([\d.]+)\s*°?\s*([NSEWnsew])$');

  /// Parses [input] and returns the decoded [SpLatLng], or `null` on failure.
  ///
  /// [referenceResolver] is called with the city/location hint when recovering
  /// a short Plus Code (e.g. "HVRG+727 Phnom Penh"). Defaults to the system
  /// geocoder. Inject a custom resolver in tests to avoid network calls.
  static Future<SpLatLng?> parse(
    String input, {
    Future<SpLatLng?> Function(String hint)? referenceResolver,
  }) async {
    final String text = input.trim();
    if (text.isEmpty) return null;

    return _tryDecimal(text) ?? _tryCardinal(text) ?? await _tryPlusCode(text, referenceResolver);
  }

  // ---------------------------------------------------------------------------
  // Decimal  "11.591237, 104.87499"
  // ---------------------------------------------------------------------------

  static SpLatLng? _tryDecimal(String text) {
    final int commaIdx = text.indexOf(',');
    if (commaIdx == -1) return null;

    final double? lat = double.tryParse(text.substring(0, commaIdx).trim());
    final double? lng = double.tryParse(text.substring(commaIdx + 1).trim());
    if (lat == null || lng == null) return null;

    return _validate(lat, lng);
  }

  // ---------------------------------------------------------------------------
  // Cardinal  "11.57934° N, 104.87423° E"
  // ---------------------------------------------------------------------------

  static SpLatLng? _tryCardinal(String text) {
    final int commaIdx = text.indexOf(',');
    if (commaIdx == -1) return null;

    final Match? m1 = _cardinalPartRegex.firstMatch(text.substring(0, commaIdx).trim());
    final Match? m2 = _cardinalPartRegex.firstMatch(text.substring(commaIdx + 1).trim());
    if (m1 == null || m2 == null) return null;

    final double? v1 = double.tryParse(m1.group(1)!);
    final double? v2 = double.tryParse(m2.group(1)!);
    if (v1 == null || v2 == null) return null;

    final String d1 = m1.group(2)!.toUpperCase();
    final String d2 = m2.group(2)!.toUpperCase();

    double? lat, lng;
    if ((d1 == 'N' || d1 == 'S') && (d2 == 'E' || d2 == 'W')) {
      lat = d1 == 'S' ? -v1 : v1;
      lng = d2 == 'W' ? -v2 : v2;
    } else if ((d1 == 'E' || d1 == 'W') && (d2 == 'N' || d2 == 'S')) {
      lng = d1 == 'W' ? -v1 : v1;
      lat = d2 == 'S' ? -v2 : v2;
    }

    if (lat == null || lng == null) return null;
    return _validate(lat, lng);
  }

  // ---------------------------------------------------------------------------
  // Plus Code  "7P28QRVW+62"  or  "X4MQ+2V Al Haram, Egypt"  or  "X4HH+QX4, Egypt"
  // ---------------------------------------------------------------------------

  static Future<SpLatLng?> _tryPlusCode(String text, Future<SpLatLng?> Function(String hint)? referenceResolver) async {
    // Split on the first space or comma to separate Plus Code from location hint.
    // Supported formats:
    //   - "7P28QRVW+62"                         (full Plus Code)
    //   - "X4MQ+2V Al Haram, Egypt"            (short code + space + hint)
    //   - "X4HH+QX4, Al Ahram, Egypt"          (short code + comma + hint)
    final int spaceIdx = text.indexOf(' ');
    final int commaIdx = text.indexOf(',');

    int delimiterIdx = -1;
    if (spaceIdx != -1 && commaIdx != -1) {
      delimiterIdx = spaceIdx < commaIdx ? spaceIdx : commaIdx;
    } else if (spaceIdx != -1) {
      delimiterIdx = spaceIdx;
    } else if (commaIdx != -1) {
      delimiterIdx = commaIdx;
    }

    final String codeToken = delimiterIdx == -1 ? text : text.substring(0, delimiterIdx);
    final String? locationHint = delimiterIdx == -1 ? null : text.substring(delimiterIdx + 1).trim();

    if (!codeToken.contains('+')) return null;

    try {
      final olc.PlusCode code = olc.PlusCode(codeToken.toUpperCase());

      if (code.isFull()) {
        final olc.CodeArea area = code.decode();
        return SpLatLng(area.center.latitude, area.center.longitude);
      }

      if (!code.isShort()) return null;

      final SpLatLng? reference = await _resolveReference(locationHint, referenceResolver);
      if (reference == null) return null;

      final olc.PlusCode full = code.recoverNearest(
        olc.LatLng(reference.latitude, reference.longitude),
      );
      final olc.CodeArea area = full.decode();
      return SpLatLng(area.center.latitude, area.center.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Geocode [locationHint] (e.g. "Phnom Penh") to get a reference point for
  /// short Plus Code recovery. Returns `null` when geocoding is unavailable or
  /// the query returns no results.
  static Future<SpLatLng?> _resolveReference(
    String? locationHint,
    Future<SpLatLng?> Function(String hint)? referenceResolver,
  ) async {
    if (locationHint == null || locationHint.isEmpty) return null;

    if (referenceResolver != null) {
      return referenceResolver(locationHint);
    }

    try {
      final results = await SpGeocodingService.systemInstance.searchPlaces(locationHint);
      if (results.isEmpty) return null;
      return results.first.latLng;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static SpLatLng? _validate(double lat, double lng) {
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return SpLatLng(lat, lng);
  }
}
