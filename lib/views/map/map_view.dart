import 'package:storypad/core/map/sp_latlng.dart';
import 'package:storypad/core/map/sp_map_marker.dart';
import 'package:storypad/core/map/sp_map_overlay_theme.dart';
import 'package:storypad/core/map/sp_map_tile_style.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/sp_fab_location.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

import 'map_view_model.dart';

part 'map_content.dart';

class MapRoute extends BaseRoute {
  const MapRoute();

  @override
  String? get routeName => "map";

  @override
  Widget buildPage(BuildContext context) => MapView(params: this);
}

class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.params,
  });

  final MapRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<MapViewModel>(
      create: (context) => MapViewModel(params: params),
      builder: (context, viewModel, child) {
        return SpMapOverlayTheme(
          brightness: viewModel.mapAdapter.overlayBrightness(viewModel.tileStyle),
          child: _MapContent(viewModel),
        );
      },
    );
  }
}
