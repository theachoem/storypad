import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:easy_localization/easy_localization.dart' show tr, BuildContextEasyLocalizationExtension;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/welcome_message_service.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/providers/in_app_update_provider.dart';
import 'package:storypad/providers/nickname_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/rewards/rewards_view.dart';
import 'package:storypad/views/root/root_view_model.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/views/settings/settings_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/sp_cross_fade.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_floating_relax_sound_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';
import 'package:storypad/widgets/sp_measure_size.dart';
import 'package:storypad/widgets/sp_multi_edit_bottom_nav_bar.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
import 'package:storypad/widgets/sp_side_bar_toggler_button.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/sp_throwback_tile.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/story_list/sp_story_listener_builder.dart';
import 'package:storypad/widgets/story_list/sp_story_tile_list_item.dart';

import 'home_view_model.dart';

part 'home_content.dart';
part 'local_widgets/app_update_floating_button.dart';
part 'local_widgets/home_app_bar.dart';
part 'local_widgets/home_app_bar_message.dart';
part 'local_widgets/home_app_bar_nickname.dart';
part 'local_widgets/home_empty.dart';
part 'local_widgets/home_flexible_space_bar.dart';
part 'local_widgets/home_floating_buttons.dart';
part 'local_widgets/home_scaffold.dart';
part 'local_widgets/home_tab_bar.dart';
part 'local_widgets/home_timeline_side_bar.dart';
part 'local_widgets/rounded_indicator.dart';
part 'local_widgets/pin_story_icon_button.dart';

class HomeRoute extends BaseRoute {
  @override
  String get routeName => 'home';

  const HomeRoute();

  @override
  Widget buildPage(BuildContext context) => const HomeView();
}

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
  });

  static BuildContext? _homeContext;
  static BuildContext? get homeContext => _homeContext;
  static Future<void> reload({
    required String debugSource,
  }) async {
    return _homeContext?.read<HomeViewModel>().reload(debugSource: debugSource);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<HomeViewModel>(
      create: (context) => HomeViewModel(),
      builder: (context, viewModel, child) {
        return Builder(
          builder: (context) {
            _homeContext = context;
            return _HomeContent(viewModel);
          },
        );
      },
    );
  }
}
