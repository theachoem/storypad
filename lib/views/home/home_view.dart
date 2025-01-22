import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:spooky/app_theme.dart';
import 'package:spooky/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:spooky/core/databases/models/story_db_model.dart';
import 'package:spooky/core/extensions/color_scheme_extensions.dart';
import 'package:spooky/core/services/date_format_service.dart';
import 'package:spooky/core/services/google_drive/google_drive_service.dart';
import 'package:spooky/core/types/path_type.dart';
import 'package:spooky/providers/backup_provider.dart';
import 'package:spooky/providers/local_auth_provider.dart';
import 'package:spooky/providers/theme_provider.dart';
import 'package:spooky/views/home/local_widgets/backup_tile.dart';
import 'package:spooky/views/home/local_widgets/home_years_view.dart';
import 'package:spooky/views/home/local_widgets/rounded_indicator.dart';
import 'package:spooky/views/archives/archives_view.dart';
import 'package:spooky/views/search/search_view.dart';
import 'package:spooky/views/tags/tags_view.dart';
import 'package:spooky/views/theme/theme_view.dart';
import 'package:spooky/widgets/sp_cross_fade.dart';
import 'package:spooky/widgets/sp_end_drawer_theme.dart';
import 'package:spooky/widgets/sp_fade_in.dart';
import 'package:spooky/widgets/sp_measure_size.dart';
import 'package:spooky/widgets/sp_nested_navigation.dart';
import 'package:spooky/widgets/sp_tap_effect.dart';
import 'package:spooky/widgets/story_list/story_list_timeline_verticle_divider.dart';
import 'package:spooky/widgets/story_list/story_listener_builder.dart';
import 'package:spooky/widgets/story_list/story_tile_list_item.dart';

import 'home_view_model.dart';

part 'home_adaptive.dart';
part 'local_widgets/home_end_drawer.dart';
part 'local_widgets/home_scaffold.dart';
part 'local_widgets/home_app_bar.dart';
part 'local_widgets/home_app_bar_nickname.dart';
part 'local_widgets/home_app_bar_message.dart';
part 'local_widgets/home_empty.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<HomeViewModel>(
      create: (context) => HomeViewModel(context),
      builder: (context, viewModel, child) {
        return _HomeAdaptive(viewModel);
      },
    );
  }
}
