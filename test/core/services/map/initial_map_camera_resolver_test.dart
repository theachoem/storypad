import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/map/initial_map_camera_resolver.dart';

void main() {
  group('InitialMapCameraResolver', () {
    test('uses selected place before device or story locations', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => const SpLatLng(11.5564, 104.9282),
        fetchStoryLocations: () async => const <SpLatLng>[SpLatLng(40.7128, -74.0060)],
      );

      final result = await resolver.resolve(
        selectedPlace: PlaceDbModel(latitude: 13.3618, longitude: 103.8606),
      );

      expect(result.source, InitialMapCameraSource.selectedPlace);
      expect(result.camera.target, const SpLatLng(13.3618, 103.8606));
      expect(result.camera.zoom, 15.0);
    });

    test('uses device place before story locations when preferred', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => const SpLatLng(11.5564, 104.9282),
        fetchStoryLocations: () async => const <SpLatLng>[SpLatLng(13.3618, 103.8606)],
      );

      final result = await resolver.resolve();

      expect(result.source, InitialMapCameraSource.devicePlace);
      expect(result.camera.target, const SpLatLng(11.5564, 104.9282));
      expect(result.camera.zoom, 13.0);
    });

    test('falls back to recent story location when device place is unavailable', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => null,
        fetchStoryLocations: () async => const <SpLatLng>[SpLatLng(11.5564, 104.9282)],
      );

      final result = await resolver.resolve();

      expect(result.source, InitialMapCameraSource.storyLocation);
      expect(result.camera.target, const SpLatLng(11.5564, 104.9282));
      expect(result.camera.zoom, 12.0);
    });

    test('centers a tight recent story cluster', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => null,
        fetchStoryLocations: () async => const <SpLatLng>[
          SpLatLng(11.5564, 104.9282),
          SpLatLng(11.5610, 104.9240),
          SpLatLng(11.5500, 104.9320),
        ],
      );

      final result = await resolver.resolve();

      expect(result.source, InitialMapCameraSource.storyLocation);
      expect(result.camera.target.latitude, closeTo(11.5558, 0.0001));
      expect(result.camera.target.longitude, closeTo(104.9280, 0.0001));
      expect(result.camera.zoom, 13.5);
    });

    test('uses the most recent story instead of averaging far-apart continents', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => null,
        fetchStoryLocations: () async => const <SpLatLng>[
          SpLatLng(11.5564, 104.9282),
          SpLatLng(37.7749, -122.4194),
          SpLatLng(40.7128, -74.0060),
        ],
      );

      final result = await resolver.resolve();

      expect(result.source, InitialMapCameraSource.storyLocation);
      expect(result.camera.target, const SpLatLng(11.5564, 104.9282));
      expect(result.camera.zoom, 12.0);
    });

    test('ignores invalid coordinates', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => const SpLatLng(120.0, 104.9282),
        fetchStoryLocations: () async => const <SpLatLng>[
          SpLatLng(double.nan, 104.9282),
          SpLatLng(11.5564, 104.9282),
        ],
      );

      final result = await resolver.resolve();

      expect(result.source, InitialMapCameraSource.storyLocation);
      expect(result.camera.target, const SpLatLng(11.5564, 104.9282));
    });

    test('uses neutral fallback when no source is available', () async {
      final resolver = InitialMapCameraResolver(
        fetchDeviceLocation: () async => null,
        fetchStoryLocations: () async => const <SpLatLng>[],
      );

      final result = await resolver.resolve();

      expect(result.source, InitialMapCameraSource.fallback);
      expect(result.camera, InitialMapCameraResolver.fallbackCamera);
    });
  });
}
