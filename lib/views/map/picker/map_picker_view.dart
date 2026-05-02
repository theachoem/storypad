import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/maps/sp_map_overlay_theme.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'package:storypad/widgets/maps/sp_flutter_map.dart';
import 'package:storypad/widgets/maps/sp_google_maps_flutter.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fab_location.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/views/map/edit_place/edit_place_view.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

import 'map_picker_view_model.dart';

part 'map_picker_content.dart';

enum MapPickerFinalAction { confirm, remove, cancel }

class MapPickerResult {
  const MapPickerResult._({
    required this.action,
    required this.place,
  });

  final MapPickerFinalAction action;
  final PlaceDbModel? place;

  factory MapPickerResult.confirm(PlaceDbModel place) {
    return MapPickerResult._(
      action: MapPickerFinalAction.confirm,
      place: place,
    );
  }

  factory MapPickerResult.remove() {
    return const MapPickerResult._(
      action: MapPickerFinalAction.remove,
      place: null,
    );
  }

  factory MapPickerResult.cancel(PlaceDbModel? initialPlace) {
    return MapPickerResult._(
      action: MapPickerFinalAction.cancel,
      place: initialPlace,
    );
  }
}

class MapPickerRoute extends BaseRoute {
  const MapPickerRoute({
    this.initialSelectedPlace,
  });

  final PlaceDbModel? initialSelectedPlace;

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
      create: (context) => MapPickerViewModel(params: params, viewContext: context),
      builder: (context, viewModel, child) {
        return SpMapOverlayTheme(
          brightness: viewModel.mapStyle.overlayBrightness,
          child: _MapPickerContent(viewModel),
        );
      },
    );
  }
}
