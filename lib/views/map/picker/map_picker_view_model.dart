import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/location/sp_app_location_service.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/core/services/map/initial_map_camera_resolver.dart';
import 'package:storypad/widgets/maps/sp_map_controller.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'map_picker_view.dart';

class MapPickerViewModel extends ChangeNotifier with DisposeAwareMixin {
  final MapPickerRoute params;

  MapPickerViewModel({
    required this.params,
  }) : _selectedPlace = params.initialSelectedPlace {
    unawaited(resolveInitialCamera());
  }

  final SpMapController mapController = SpMapController();

  SpMapCamera _initialSpMapCamera = InitialMapCameraResolver.fallbackCamera;

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

  SpMapCamera get initialSpMapCamera => _initialSpMapCamera;

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

  Future<void> resolveInitialCamera() async {
    final resolver = InitialMapCameraResolver(
      fetchDevicePlace: SpLocationService.fetchLastKnownPlace,
      fetchStoryLocations: () async {
        final stories = await StoryDbModel.db.getRecentStoriesWithLocation();
        return stories.map((story) => story.location).toList();
      },
    );

    final result = await resolver.resolve(selectedPlace: params.initialSelectedPlace);
    if (disposed) return;
    if (params.initialSelectedPlace == null && _selectedPlace != null) return;

    _initialSpMapCamera = result.camera;
    notifyListeners();

    if (result.source != InitialMapCameraSource.fallback) {
      await mapController.animateTo(
        result.camera.target.latitude,
        result.camera.target.longitude,
        zoom: result.camera.zoom,
        bearing: 0.0,
      );
    }
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

  Future<void> goToCurrentLocation(BuildContext context) async {
    final place = await SpAppLocationService.fetchCurrentPlaceWithRecovery(context);
    if (!context.mounted || place == null) return;

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
