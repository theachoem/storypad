import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'package:storypad/widgets/maps/sp_map_dot_marker.dart';

void main() {
  group('SpMapDotMarker', () {
    // Google Maps caches one bitmap per key: two styles sharing a key would show the wrong color.
    test('each map style has its own icon cache key', () {
      final keys = SpMapStyle.values.map(SpMapDotMarker.iconCacheKeyFor).toSet();
      expect(keys, hasLength(SpMapStyle.values.length));
    });

    test('the dot color differs between light and dark map styles', () {
      expect(SpMapDotMarker.colorFor(SpMapStyle.streets), isNot(SpMapDotMarker.colorFor(SpMapStyle.satellite)));
    });
  });
}
