import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/geocoding/sp_coordinate_parser_service.dart';
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

    _resolveVersion += 1;
    final int version = _resolveVersion;
    _isResolving = true;
    _errorText = null;
    notifyListeners();

    try {
      final SpLatLng? latLng = await SpCoordinateParserService.parse(text);
      if (version != _resolveVersion || disposed) return;

      if (latLng == null) {
        _resolvedPlace = null;
        _errorText = 'Invalid coordinate format';
        return;
      }

      final PlaceDbModel? result = await SpGeocodingService.systemInstance.reverseGeocode(latLng);
      if (version != _resolveVersion || disposed) return;

      _resolvedPlace = result ?? PlaceDbModel(latitude: latLng.latitude, longitude: latLng.longitude);
    } catch (_) {
      if (version == _resolveVersion) {
        _resolvedPlace = null;
        _errorText = null;
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    coordinateController.removeListener(_onTextChanged);
    coordinateController.dispose();
    super.dispose();
  }
}
