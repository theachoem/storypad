import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_map_controller.dart';
import 'map_view.dart';
import 'local_widgets/maps/map_types.dart';

class MapViewModel extends ChangeNotifier with DisposeAwareMixin {
  final MapRoute params;

  MapViewModel({
    required this.params,
  });

  MapJournalCamera get initialCamera => const MapJournalCamera(
    location: MapJournalLocation(latitude: 37.7815, longitude: -122.4310),
    zoom: 10.8,
  );

  SpMapCamera get initialSpMapCamera => SpMapCamera(
    target: SpMapPoint(
      latitude: initialCamera.location.latitude,
      longitude: initialCamera.location.longitude,
    ),
    zoom: initialCamera.zoom,
  );

  SpMapRenderer get mapRenderer => SpMapRenderer.googleMaps;

  final SpMapController mapController = SpMapController();

  bool _isPreparingMarkers = true;
  bool get isPreparingMarkers => _isPreparingMarkers;

  void setMarkersPreparing(bool preparing) {
    if (disposed || _isPreparingMarkers == preparing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (disposed || _isPreparingMarkers == preparing) return;
      _isPreparingMarkers = preparing;
      notifyListeners();
    });
  }

  Future<void> goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final Position position = await Geolocator.getCurrentPosition();
      await mapController.animateTo(
        position.latitude,
        position.longitude,
        zoom: 15.0,
        bearing: 0.0,
      );
    } catch (_) {}
  }

  Future<void> resetRotation() async {
    await mapController.resetRotation();
  }

  void handleEntryTap(BuildContext context, MapJournalEntry entry) {
    debugPrint('Map journal entry tapped: ${entry.title}');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${entry.title} - ${entry.locationLabel}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  SpMapStyle _mapStyle = SpMapStyle.streets;
  SpMapStyle get mapStyle => _mapStyle;

  List<MapJournalEntry> get entries => _mockEntries;

  List<SpMapMarker<MapJournalEntry>> get mapMarkers {
    return entries
        .map(
          (entry) => SpMapMarker<MapJournalEntry>(
            id: entry.id,
            point: SpMapPoint(
              latitude: entry.location.latitude,
              longitude: entry.location.longitude,
            ),
            data: entry,
            title: entry.title,
            snippet: '${entry.dateLabel} - ${entry.locationLabel}',
            size: const Size(62.0, 74.0),
            alignment: Alignment.topCenter,
            anchor: const Offset(0.5, 1.0),
          ),
        )
        .toList();
  }

  void setMapStyle(SpMapStyle mapStyle) {
    if (_mapStyle == mapStyle) return;

    _mapStyle = mapStyle;
    notifyListeners();
  }
}

class MapJournalCamera {
  const MapJournalCamera({
    required this.location,
    required this.zoom,
  });

  final MapJournalLocation location;
  final double zoom;
}

class MapJournalLocation {
  const MapJournalLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class MapJournalEntry {
  const MapJournalEntry({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.locationLabel,
    required this.location,
    required this.markerText,
    required this.color,
    this.imageAssetPath,
  });

  final String id;
  final String title;
  final String dateLabel;
  final String locationLabel;
  final MapJournalLocation location;
  final String markerText;
  final Color color;
  final String? imageAssetPath;

  bool get hasImage => imageAssetPath != null;
}

const List<MapJournalEntry> _mockEntries = <MapJournalEntry>[
  MapJournalEntry(
    id: 'ferry-building-morning',
    title: 'Morning pages',
    dateLabel: 'Apr 24',
    locationLabel: 'North Beach',
    location: MapJournalLocation(latitude: 37.8017, longitude: -122.4109),
    markerText: 'MP',
    color: Color(0xFF4B7F52),
    imageAssetPath: 'assets/images/onboarding/light_home_300x360.jpg',
  ),
  MapJournalEntry(
    id: 'north-beach-coffee',
    title: 'Coffee and quiet',
    dateLabel: 'Apr 22',
    locationLabel: 'North Beach',
    location: MapJournalLocation(latitude: 37.7995, longitude: -122.4076),
    markerText: 'CQ',
    color: Color(0xFFC1663A),
  ),
  MapJournalEntry(
    id: 'north-beach-postcard',
    title: 'Postcard draft',
    dateLabel: 'Apr 21',
    locationLabel: 'North Beach',
    location: MapJournalLocation(latitude: 37.8035, longitude: -122.4061),
    markerText: 'PD',
    color: Color(0xFFB85C38),
  ),
  MapJournalEntry(
    id: 'north-beach-bookshop',
    title: 'Bookshop margin note',
    dateLabel: 'Apr 20',
    locationLabel: 'North Beach',
    location: MapJournalLocation(latitude: 37.7980, longitude: -122.4125),
    markerText: 'BM',
    color: Color(0xFF8A5A44),
  ),
  MapJournalEntry(
    id: 'mission-walk',
    title: 'Long walk after rain',
    dateLabel: 'Apr 18',
    locationLabel: 'Mission District',
    location: MapJournalLocation(latitude: 37.7595, longitude: -122.4156),
    markerText: 'LW',
    color: Color(0xFF4464AD),
    imageAssetPath: 'assets/images/onboarding/dark_story_details_300x360.jpg',
  ),
  MapJournalEntry(
    id: 'mission-late-note',
    title: 'Late note',
    dateLabel: 'Apr 17',
    locationLabel: 'Mission District',
    location: MapJournalLocation(latitude: 37.7567, longitude: -122.4189),
    markerText: 'LN',
    color: Color(0xFF345E9E),
  ),
  MapJournalEntry(
    id: 'dolores-reading',
    title: 'Read until sunset',
    dateLabel: 'Apr 16',
    locationLabel: 'Dolores Park',
    location: MapJournalLocation(latitude: 37.7617, longitude: -122.4264),
    markerText: 'RS',
    color: Color(0xFF735CDD),
  ),
  MapJournalEntry(
    id: 'dolores-picnic',
    title: 'Picnic notes',
    dateLabel: 'Apr 15',
    locationLabel: 'Dolores Park',
    location: MapJournalLocation(latitude: 37.7585, longitude: -122.4298),
    markerText: 'PN',
    color: Color(0xFF654ED2),
    imageAssetPath: 'assets/images/onboarding/light_drawer_signed_in_221x510.jpg',
  ),
  MapJournalEntry(
    id: 'haight-note',
    title: 'A note from the bus',
    dateLabel: 'Apr 14',
    locationLabel: 'Haight-Ashbury',
    location: MapJournalLocation(latitude: 37.7698, longitude: -122.4491),
    markerText: 'BN',
    color: Color(0xFF0F8B8D),
  ),
  MapJournalEntry(
    id: 'haight-record-shop',
    title: 'Record shop thought',
    dateLabel: 'Apr 13',
    locationLabel: 'Haight-Ashbury',
    location: MapJournalLocation(latitude: 37.7712, longitude: -122.4450),
    markerText: 'RT',
    color: Color(0xFF118C75),
  ),
  MapJournalEntry(
    id: 'golden-gate-garden',
    title: 'Garden air',
    dateLabel: 'Apr 11',
    locationLabel: 'Golden Gate Park',
    location: MapJournalLocation(latitude: 37.7691, longitude: -122.4826),
    markerText: 'GA',
    color: Color(0xFF526A31),
    imageAssetPath: 'assets/images/onboarding/light_story_details_300x360.jpg',
  ),
  MapJournalEntry(
    id: 'presidio-fog',
    title: 'Fog over the trail',
    dateLabel: 'Apr 09',
    locationLabel: 'Presidio',
    location: MapJournalLocation(latitude: 37.7867, longitude: -122.4789),
    markerText: 'FT',
    color: Color(0xFF6A7FDB),
    imageAssetPath: 'assets/images/onboarding/dark_home_300x360.jpg',
  ),
  MapJournalEntry(
    id: 'hayes-window',
    title: 'Window seat draft',
    dateLabel: 'Apr 07',
    locationLabel: 'Hayes Valley',
    location: MapJournalLocation(latitude: 37.7778, longitude: -122.4248),
    markerText: 'WD',
    color: Color(0xFF9B5DE5),
  ),
  MapJournalEntry(
    id: 'hayes-evening',
    title: 'Evening outline',
    dateLabel: 'Apr 06',
    locationLabel: 'Hayes Valley',
    location: MapJournalLocation(latitude: 37.7751, longitude: -122.4212),
    markerText: 'EO',
    color: Color(0xFF8750CF),
  ),
  MapJournalEntry(
    id: 'hayes-sketch',
    title: 'Tiny sketch',
    dateLabel: 'Apr 05',
    locationLabel: 'Hayes Valley',
    location: MapJournalLocation(latitude: 37.7793, longitude: -122.4217),
    markerText: 'TS',
    color: Color(0xFF7A4FC1),
    imageAssetPath: 'assets/images/onboarding/dark_drawer_signed_in_221x510.jpg',
  ),
];
