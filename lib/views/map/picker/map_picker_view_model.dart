import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
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

  PlaceDbModel? _selectedPlace;
  PlaceDbModel? get selectedPlace => _selectedPlace;

  bool _isResolvingPlace = false;
  bool get isResolvingPlace => _isResolvingPlace;
  int _selectedVersion = 0;

  bool get canRemove => params.initialSelectedPlace != null;
  bool get hasSelectedPlace => _selectedPlace != null;

  SpMapCamera get initialSpMapCamera {
    if (params.initialSelectedPlace != null) {
      return SpMapCamera(
        target: SpLatLng(params.initialSelectedPlace!.latitude, params.initialSelectedPlace!.longitude),
        zoom: 15.0,
      );
    }

    return const SpMapCamera(
      target: SpLatLng(37.7815, -122.4310),
      zoom: 10.8,
    );
  }

  List<SpMapMarker<PlaceDbModel>> get selectedMarkers {
    final PlaceDbModel? selectedPlace = _selectedPlace;
    if (selectedPlace == null) return <SpMapMarker<PlaceDbModel>>[];

    return <SpMapMarker<PlaceDbModel>>[
      SpMapMarker<PlaceDbModel>(
        id: 'selected-location',
        point: SpLatLng(selectedPlace.latitude, selectedPlace.longitude),
        data: selectedPlace,
        title: selectedPlace.displayLabel,
        clusterable: false,
        size: const Size.square(42.0),
      ),
    ];
  }

  PlaceDbModel? get initialSelectedPlace => params.initialSelectedPlace;

  bool get canConfirm {
    final PlaceDbModel? selectedPlace = _selectedPlace;
    if (selectedPlace == null || _isResolvingPlace) return false;

    final PlaceDbModel? initialPlace = params.initialSelectedPlace;
    if (initialPlace == null) return true;
    return selectedPlace.latitude != initialPlace.latitude || selectedPlace.longitude != initialPlace.longitude;
  }

  void setMapStyle(SpMapStyle mapStyle) {
    if (_mapStyle == mapStyle) return;
    _mapStyle = mapStyle;
    notifyListeners();
  }

  void setSelectedLocation(double latitude, double longitude) {
    _selectedVersion += 1;
    _selectedPlace = PlaceDbModel(
      latitude: latitude,
      longitude: longitude,
    );

    notifyListeners();
    unawaited(_resolveSelectedPlace(selectedVersion: _selectedVersion));
  }

  Future<void> goToCurrentLocation() async {
    final place = await SpLocationService.fetchCurrentPlace();
    if (place == null) return;

    _selectedVersion += 1;
    _selectedPlace = place;
    notifyListeners();

    await mapController.animateTo(
      place.latitude,
      place.longitude,
      zoom: 15.0,
      bearing: 0.0,
    );
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
    final PlaceDbModel? place = _selectedPlace;
    if (place == null ||
        (place.placeName != null && place.placeName!.trim().isNotEmpty) ||
        (place.locality != null && place.locality!.trim().isNotEmpty)) {
      return;
    }

    _isResolvingPlace = true;
    notifyListeners();

    try {
      final resolved = await SpGeocodingService.instance.reverseGeocode(place.latLng);
      if (selectedVersion != _selectedVersion) return;

      _selectedPlace = resolved ?? place;
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
}
