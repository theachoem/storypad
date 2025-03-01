import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/routes/base_route.dart';
import 'package:storypad/views/library/show/show_asset_view.dart';
import 'package:storypad/widgets/custom_embed/sp_image.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

import 'library_view_model.dart';

part 'library_content.dart';

class LibraryRoute extends BaseRoute {
  LibraryRoute();

  @override
  Widget buildPage(BuildContext context) => LibraryView(params: this);

  @override
  bool get preferredNestedRoute => true;
}

class LibraryView extends StatelessWidget {
  const LibraryView({
    super.key,
    required this.params,
  });

  final LibraryRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<LibraryViewModel>(
      create: (context) => LibraryViewModel(params: params),
      builder: (context, viewModel, child) {
        return _LibraryContent(viewModel);
      },
    );
  }
}
