import 'package:flutter/material.dart';
import 'package:storypad/core/map/sp_map_marker.dart';
import 'package:storypad/core/map/sp_map_overlay_theme.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/core/services/geocoding/sp_place_result.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/sp_fab_location.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'location_picker_view_model.dart';

part 'location_picker_content.dart';

class LocationPickerRoute extends BaseRoute {
  const LocationPickerRoute({
    this.initialPlace,
    this.onDelete,
  });

  /// Pre-select an existing place when editing an already-pinned location.
  final SpPlaceResult? initialPlace;

  /// Called when the user taps the delete button inside the picker.
  /// Use this to remove the location from the story entry.
  final VoidCallback? onDelete;

  @override
  Widget buildPage(BuildContext context) => LocationPickerView(params: this);
}

class LocationPickerView extends StatelessWidget {
  const LocationPickerView({
    super.key,
    required this.params,
  });

  final LocationPickerRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<LocationPickerViewModel>(
      create: (context) => LocationPickerViewModel(params: params),
      builder: (context, viewModel, child) {
        return SpMapOverlayTheme(
          brightness: viewModel.mapAdapter.overlayBrightness(viewModel.tileStyle),
          child: _LocationPickerContent(viewModel),
        );
      },
    );
  }
}
