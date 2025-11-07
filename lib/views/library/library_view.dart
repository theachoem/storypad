import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/views/library/show/show_asset_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_info_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_playback_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_image.dart';
import 'package:storypad/widgets/sp_images_viewer.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_scrollable_choice_chips.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'library_view_model.dart';

part 'library_content.dart';
part 'local_widgets/empty_body.dart';
part 'local_widgets/black_overlay.dart';
part 'local_widgets/image_status.dart';
part 'local_widgets/images_tab_content.dart';
part 'local_widgets/voices_tab_content.dart';

class LibraryRoute extends BaseRoute {
  LibraryRoute();

  @override
  Widget buildPage(BuildContext context) => LibraryView(params: this);
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
        return LayoutBuilder(
          builder: (context, constraints) {
            return _LibraryContent(viewModel, constraints: constraints);
          },
        );
      },
    );
  }
}
