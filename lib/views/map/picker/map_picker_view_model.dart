import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_map_controller.dart';
import 'package:storypad/views/map/local_widgets/maps/map_types.dart';
import 'map_picker_view.dart';

class MapPickerViewModel extends ChangeNotifier with DisposeAwareMixin {
  final MapPickerRoute params;

  MapPickerViewModel({
    required this.params,
  }) : _selectedPlace = params.initialSelectedPlace;

  final SpMapController mapController = SpMapController();

  SpMapRenderer get mapRenderer => SpMapRenderer.googleMaps;

  SpMapStyle _mapStyle = SpMapStyle.streets;
  SpMapStyle get mapStyle => _mapStyle;

  PlaceObject? _selectedPlace;
  PlaceObject? get selectedPlace => _selectedPlace;

  bool _isResolvingPlace = false;
  bool get isResolvingPlace => _isResolvingPlace;
  int _selectedVersion = 0;

  bool get canRemove => params.initialSelectedPlace != null;
  bool get hasSelectedPlace => _selectedPlace != null;

  MapPickerCamera get initialCamera {
    if (params.initialSelectedPlace != null) {
      return MapPickerCamera(
        latitude: params.initialSelectedPlace!.latitude,
        longitude: params.initialSelectedPlace!.longitude,
        zoom: 15.0,
      );
    }

    return const MapPickerCamera(
      latitude: 37.7815,
      longitude: -122.4310,
      zoom: 10.8,
    );
  }

  SpMapCamera get initialSpMapCamera => SpMapCamera(
    target: SpMapPoint(
      latitude: initialCamera.latitude,
      longitude: initialCamera.longitude,
    ),
    zoom: initialCamera.zoom,
  );

  List<SpMapMarker<PlaceObject>> get selectedMarkers {
    final PlaceObject? selectedPlace = _selectedPlace;
    if (selectedPlace == null) return <SpMapMarker<PlaceObject>>[];

    return <SpMapMarker<PlaceObject>>[
      SpMapMarker<PlaceObject>(
        id: 'selected-location',
        point: SpMapPoint(
          latitude: selectedPlace.latitude,
          longitude: selectedPlace.longitude,
        ),
        data: selectedPlace,
        title: selectedPlace.displayLabel,
        clusterable: false,
        size: const Size.square(42.0),
      ),
    ];
  }

  PlaceObject? get initialSelectedPlace => params.initialSelectedPlace;

  void setMapStyle(SpMapStyle mapStyle) {
    if (_mapStyle == mapStyle) return;
    _mapStyle = mapStyle;
    notifyListeners();
  }

  void setSelectedLocation(double latitude, double longitude) {
    _selectedVersion += 1;
    _selectedPlace = PlaceObject(
      latitude: latitude,
      longitude: longitude,
      placeName: null,
      locality: null,
      country: null,
      address: null,
    );
    notifyListeners();

    unawaited(_resolveSelectedPlace(selectedVersion: _selectedVersion));
  }

  Future<void> goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();
      setSelectedLocation(position.latitude, position.longitude);
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

  Future<MapPickerResult?> buildConfirmResult() async {
    if (_selectedPlace == null) return null;

    if (_selectedPlace!.placeName == null && _selectedPlace!.locality == null) {
      await _resolveSelectedPlace(selectedVersion: _selectedVersion);
    }

    if (_selectedPlace == null) return null;

    return MapPickerResult.confirm(_selectedPlace!);
  }

  Future<void> _resolveSelectedPlace({required int selectedVersion}) async {
    final PlaceObject? place = _selectedPlace;
    if (place == null ||
        (place.placeName != null && place.placeName!.trim().isNotEmpty) ||
        (place.locality != null && place.locality!.trim().isNotEmpty)) {
      return;
    }

    _isResolvingPlace = true;
    notifyListeners();

    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        place.latitude,
        place.longitude,
      );

      final Placemark? placemark = placemarks.isEmpty ? null : placemarks.first;

      final String? placeName = _firstNonEmpty(<String?>[
        placemark?.name,
        placemark?.street,
        placemark?.subLocality,
      ]);
      final String? locality = _firstNonEmpty(<String?>[
        placemark?.locality,
        placemark?.subAdministrativeArea,
      ]);
      final String? country = _normalizeNullable(placemark?.country);
      final String? address = _joinAddressParts(<String?>[
        placemark?.name,
        placemark?.street,
        placemark?.subLocality,
        placemark?.locality,
        placemark?.administrativeArea,
        placemark?.country,
      ]);

      if (selectedVersion != _selectedVersion) return;

      _selectedPlace = PlaceObject(
        latitude: place.latitude,
        longitude: place.longitude,
        placeName: placeName,
        locality: locality,
        country: country,
        address: address,
      );
    } catch (_) {
      if (selectedVersion == _selectedVersion) {
        _selectedPlace = place;
      }
    } finally {
      if (selectedVersion == _selectedVersion) {
        _isResolvingPlace = false;
        if (!disposed) {
          notifyListeners();
        }
      }
    }
  }

  String? _normalizeNullable(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final String? value in values) {
      final String? normalized = _normalizeNullable(value);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _joinAddressParts(List<String?> values) {
    final List<String> parts = values.map(_normalizeNullable).whereType<String>().toSet().toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}

class MapPickerCamera {
  const MapPickerCamera({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final double latitude;
  final double longitude;
  final double zoom;
}
