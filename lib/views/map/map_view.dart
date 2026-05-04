import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/adapters/objectbox/stories_box.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:storypad/widgets/maps/sp_map_overlay_theme.dart';
import 'package:storypad/widgets/maps/sp_flutter_map.dart';
import 'package:storypad/widgets/maps/sp_google_maps_flutter.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:provider/provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fab_location.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

import 'map_view_model.dart';
import '../../widgets/maps/map_types.dart';

part 'map_content.dart';
part 'local_widgets/marker_preparing_pill.dart';

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
    return ChangeNotifierProvider<MapViewModel>(
      create: (context) => MapViewModel(params: params, viewContext: context),
      builder: (context, child) {
        final viewModel = Provider.of<MapViewModel>(context);

        return SpMapOverlayTheme(
          brightness: viewModel.mapStyle.overlayBrightness,
          child: _MapContent(viewModel),
        );
      },
    );
  }
}
