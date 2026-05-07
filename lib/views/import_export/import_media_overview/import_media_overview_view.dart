import 'dart:math';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_asset_status_badge.dart';
import 'package:storypad/widgets/sp_asset_story_count_overlay.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'import_media_overview_view_model.dart';

part 'import_media_overview_content.dart';

class ImportMediaOverviewRoute extends BaseRoute {
  const ImportMediaOverviewRoute({required this.tarFilePath});

  final String tarFilePath;

  @override
  Widget buildPage(BuildContext context) => ImportMediaOverviewView(params: this);
}

class ImportMediaOverviewView extends StatelessWidget {
  const ImportMediaOverviewView({
    super.key,
    required this.params,
  });

  final ImportMediaOverviewRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ImportMediaOverviewViewModel>(
      create: (context) => ImportMediaOverviewViewModel(params: params),
      builder: (context, child) {
        return _ImportMediaOverviewContent(Provider.of(context));
      },
    );
  }
}
