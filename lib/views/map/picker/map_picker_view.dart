import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/views/map/local_widgets/sp_map_side_button.dart';
import 'package:storypad/views/map/local_widgets/maps/map_types.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_flutter_map.dart';
import 'package:storypad/views/map/local_widgets/maps/sp_google_maps_flutter.dart';
import 'package:storypad/widgets/bottom_sheets/sp_map_style_sheet.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'map_picker_view_model.dart';

part 'map_picker_content.dart';

class PlaceObject {
  final double latitude;
  final double longitude;

  /// Human-readable place name, e.g. "Knowledge Cafe".
  final String? placeName;

  /// City / locality, e.g. "Phnom Penh".
  /// Maps to DayOne `localityName` and Apple Journal `city`.
  final String? locality;

  /// Country name, e.g. "Cambodia".
  final String? country;

  /// Full formatted address string.
  final String? address;

  PlaceObject({
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.locality,
    required this.country,
    required this.address,
  });

  /// Display label: placeName if available, otherwise locality, otherwise coordinates.
  String get displayLabel {
    if (placeName != null) return placeName!;
    if (locality != null) return locality!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  int compareTo(PlaceObject? initialSelectedPlace) {
    if (initialSelectedPlace == null) return 1;
    if (latitude != initialSelectedPlace.latitude) return 1;
    if (longitude != initialSelectedPlace.longitude) return 1;
    return 0;
  }
}

enum MapPickerFinalAction { confirm, remove, cancel }

class MapPickerResult {
  final MapPickerFinalAction action;
  final PlaceObject? place;

  MapPickerResult._({required this.action, required this.place});

  factory MapPickerResult.confirm(PlaceObject place) =>
      MapPickerResult._(action: MapPickerFinalAction.confirm, place: place);

  factory MapPickerResult.remove() => MapPickerResult._(action: MapPickerFinalAction.remove, place: null);

  factory MapPickerResult.cancel(PlaceObject? initialPlace) =>
      MapPickerResult._(action: MapPickerFinalAction.cancel, place: initialPlace);
}

class MapPickerRoute extends BaseRoute {
  const MapPickerRoute({
    this.initialSelectedPlace,
  });

  final PlaceObject? initialSelectedPlace;

  @override
  Widget buildPage(BuildContext context) => MapPickerView(params: this);
}

class MapPickerView extends StatelessWidget {
  const MapPickerView({
    super.key,
    required this.params,
  });

  final MapPickerRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<MapPickerViewModel>(
      create: (context) => MapPickerViewModel(params: params),
      builder: (context, viewModel, child) {
        return _MapPickerContent(viewModel);
      },
    );
  }
}
