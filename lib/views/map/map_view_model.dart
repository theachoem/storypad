import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/map/flutter_map/sp_flutter_map_adapter.dart';
import 'package:storypad/core/map/google_maps/sp_google_maps_adapter.dart';
import 'package:storypad/core/map/sp_map_adapter.dart';
import 'package:storypad/core/map/sp_map_controller.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'map_view.dart';

class MapViewModel extends ChangeNotifier with DisposeAwareMixin {
  final MapRoute params;

  /// Global singleton that selects the right [SpMapAdapter] for the current platform.
  ///
  /// - iOS / Android → [SpGoogleMapsAdapter]
  /// - macOS / Windows / Linux / Web → [SpFlutterMapAdapter]
  final SpMapAdapter mapAdapter = (Platform.isAndroid || Platform.isIOS)
      ? SpGoogleMapsAdapter()
      : SpFlutterMapAdapter();

  MapViewModel({required this.params}) {
    mapController = mapAdapter.createController();
  }

  late final SpMapController mapController;

  SpMapTileStyle _tileStyle = SpMapTileStyle.streets;
  SpMapTileStyle get tileStyle => _tileStyle;

  void toggleTileStyle() {
    _tileStyle = _tileStyle.toggled;
    notifyListeners();
  }
}
