import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/map/flutter_map/sp_flutter_map_adapter.dart';
import 'package:storypad/core/map/google_maps/sp_google_maps_adapter.dart';
import 'package:storypad/core/map/sp_latlng.dart';
import 'package:storypad/core/map/sp_map_adapter.dart';
import 'package:storypad/core/map/sp_map_controller.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'package:storypad/core/services/geocoding/sp_place_result.dart';
import 'package:storypad/core/services/location/sp_location_service.dart';
import 'package:storypad/views/map/location_picker/location_picker_view.dart';

const double kLocationZoom = 15.0;

class LocationPickerViewModel extends ChangeNotifier with DisposeAwareMixin {
  final LocationPickerRoute params;

  LocationPickerViewModel({required this.params}) {
    if (params.initialPlace != null) {
      _selectedLatLng = SpLatLng(params.initialPlace!.latitude, params.initialPlace!.longitude);
      _result = params.initialPlace;
    }
    mapController = mapAdapter.createController();
  }

  /// The initial camera position — used to centre the map when it first mounts.
  SpLatLng? get initialLatLng =>
      params.initialPlace != null ? SpLatLng(params.initialPlace!.latitude, params.initialPlace!.longitude) : null;

  final SpMapAdapter mapAdapter = (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      ? SpGoogleMapsAdapter()
      : SpFlutterMapAdapter();

  late final SpMapController mapController;

  SpLatLng? _selectedLatLng;
  SpLatLng? get selectedLatLng => _selectedLatLng;

  SpPlaceResult? _result;
  SpPlaceResult? get result => _result;

  bool _isGeocoding = false;
  bool get isGeocoding => _isGeocoding;

  bool _isFetchingLocation = false;
  bool get isFetchingLocation => _isFetchingLocation;

  SpMapTileStyle _tileStyle = SpMapTileStyle.streets;
  SpMapTileStyle get tileStyle => _tileStyle;

  void toggleTileStyle() {
    _tileStyle = _tileStyle.toggled;
    notifyListeners();
  }

  /// Called when the user taps the map. Places a pin and kicks off
  /// reverse geocoding.
  Future<void> onMapTap(SpLatLng latLng) async {
    _selectedLatLng = latLng;
    _result = null;
    _isGeocoding = true;
    notifyListeners();

    final place = await SpGeocodingService.instance.reverseGeocode(latLng);
    _result = place ?? SpPlaceResult(latitude: latLng.latitude, longitude: latLng.longitude);
    _isGeocoding = false;
    notifyListeners();
  }

  /// Returns the confirmed [SpPlaceResult] via [Navigator.pop].
  void confirm(BuildContext context) {
    Navigator.of(context).pop(_result);
  }

  /// Calls [LocationPickerRoute.onDelete] and closes the picker.
  void deleteLocation(BuildContext context) {
    params.onDelete?.call();
    Navigator.of(context).pop();
  }

  /// Uses the device GPS to get the current position and pins it.
  Future<void> fetchCurrentLocation() async {
    _isFetchingLocation = true;
    notifyListeners();

    final place = await SpLocationService.fetchCurrentPlace();

    if (place != null) {
      _isFetchingLocation = false;
      await onMapTap(SpLatLng(place.latitude, place.longitude));
      await mapController.animateTo(SpLatLng(place.latitude, place.longitude), zoom: kLocationZoom);
    } else {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }
}
