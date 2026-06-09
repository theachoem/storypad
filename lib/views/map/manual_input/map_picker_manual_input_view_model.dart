import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_geocoding_service.dart';
import 'map_picker_manual_input_view.dart';

class MapPickerManualInputViewModel extends ChangeNotifier with DisposeAwareMixin {
  final MapPickerManualInputRoute params;

  MapPickerManualInputViewModel({
    required this.params,
  }) {
    coordinateController = TextEditingController();
    coordinateController.addListener(_onTextChanged);
  }

  late final TextEditingController coordinateController;

  PlaceDbModel? _resolvedPlace;
  PlaceDbModel? get resolvedPlace => _resolvedPlace;

  bool _isResolving = false;
  bool get isResolving => _isResolving;

  String? _errorText;
  String? get errorText => _errorText;

  int _resolveVersion = 0;
  Timer? _debounceTimer;

  bool get canConfirm => _resolvedPlace != null && !_isResolving;

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), _tryResolve);
  }

  Future<void> _tryResolve() async {
    final String text = coordinateController.text.trim();
    if (text.isEmpty) {
      _resolvedPlace = null;
      _errorText = null;
      notifyListeners();
      return;
    }

    final (double? lat, double? lng, String? err) = _parseCoordinates(text);
    if (err != null || lat == null || lng == null) {
      _resolvedPlace = null;
      _errorText = err;
      notifyListeners();
      return;
    }

    _resolveVersion += 1;
    final int version = _resolveVersion;
    _isResolving = true;
    _errorText = null;
    notifyListeners();

    try {
      final PlaceDbModel? result = await SpGeocodingService.systemInstance.reverseGeocode(SpLatLng(lat, lng));
      if (version != _resolveVersion || disposed) return;

      _resolvedPlace = result ?? PlaceDbModel(latitude: lat, longitude: lng);
    } catch (_) {
      if (version == _resolveVersion) {
        _resolvedPlace = PlaceDbModel(latitude: lat, longitude: lng);
      }
    } finally {
      if (version == _resolveVersion && !disposed) {
        _isResolving = false;
        notifyListeners();
      }
    }
  }

  void apply(BuildContext context) {
    final PlaceDbModel? place = _resolvedPlace;
    if (place == null) return;
    Navigator.of(context).pop(place);
  }

  // Matches "11.57934° N" or "11.57934°N" or "11.57934 N"
  static final _cardinalPartRegex = RegExp(r'^([\d.]+)\s*°?\s*([NSEWnsew])$');

  (double? lat, double? lng, String? error) _parseCoordinates(String text) {
    // Try cardinal format: "11.57934° N, 104.87423° E"
    final int commaIndex = text.indexOf(',');
    if (commaIndex != -1) {
      final String first = text.substring(0, commaIndex).trim();
      final String second = text.substring(commaIndex + 1).trim();

      final Match? m1 = _cardinalPartRegex.firstMatch(first);
      final Match? m2 = _cardinalPartRegex.firstMatch(second);

      if (m1 != null && m2 != null) {
        final double? v1 = double.tryParse(m1.group(1)!);
        final double? v2 = double.tryParse(m2.group(1)!);
        final String d1 = m1.group(2)!.toUpperCase();
        final String d2 = m2.group(2)!.toUpperCase();

        if (v1 != null && v2 != null) {
          // Determine which part is lat and which is lng by cardinal letter.
          double? lat, lng;
          if ((d1 == 'N' || d1 == 'S') && (d2 == 'E' || d2 == 'W')) {
            lat = d1 == 'S' ? -v1 : v1;
            lng = d2 == 'W' ? -v2 : v2;
          } else if ((d1 == 'E' || d1 == 'W') && (d2 == 'N' || d2 == 'S')) {
            lng = d1 == 'W' ? -v1 : v1;
            lat = d2 == 'S' ? -v2 : v2;
          }

          if (lat != null && lng != null) {
            if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
              return (null, null, 'Latitude must be -90 to 90, longitude -180 to 180');
            }
            return (lat, lng, null);
          }
        }
      }
    }

    // Try plain decimal format: "8.528509, 47.377443"
    final List<String> parts = text.split(',');
    if (parts.length == 2) {
      final double? lat = double.tryParse(parts[0].trim());
      final double? lng = double.tryParse(parts[1].trim());

      if (lat != null && lng != null) {
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          return (null, null, 'Latitude must be -90 to 90, longitude -180 to 180');
        }
        return (lat, lng, null);
      }
    }

    return (null, null, 'Enter as "lat, lng" or "11.57934° N, 104.87423° E"');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    coordinateController.removeListener(_onTextChanged);
    coordinateController.dispose();
    super.dispose();
  }
}
