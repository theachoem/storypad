import 'dart:math';
import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart' show AppTheme;
import 'package:easy_localization/easy_localization.dart' show tr, BuildContextEasyLocalizationExtension;
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/welcome_message_service.dart' show WelcomeMessageService;
import 'package:storypad/providers/app_lock_provider.dart' show AppLockProvider;
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer.dart' show HomeEndDrawer;
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/settings/settings_view.dart' show SettingsRoute;
import 'package:storypad/views/throwback/throwback_view.dart';
import 'package:storypad/widgets/base_view/desktop_main_menu_padding.dart';
import 'package:storypad/widgets/bottom_sheets/sp_calendar_sheet.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart' show SpAppLockWrapper;
import 'package:storypad/widgets/sp_floating_relax_sound_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_multi_edit_bottom_nav_bar.dart' show SpMultiEditBottomNavBar;
import 'package:storypad/widgets/sp_nested_navigation.dart' show SpNestedNavigation;
import 'package:storypad/widgets/sp_onboarding_wrapper.dart' show SpOnboardingWrapper;
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart' show SpStoryListMultiEditWrapper;
import 'package:storypad/widgets/base_view/view_model_provider.dart' show ViewModelProvider;
import 'package:storypad/core/databases/models/story_db_model.dart' show StoryDbModel;
import 'package:storypad/core/extensions/color_scheme_extension.dart' show ColorSchemeExtension;
import 'package:storypad/core/helpers/date_format_helper.dart' show DateFormatHelper;
import 'package:storypad/providers/in_app_update_provider.dart' show InAppUpdateProvider;
import 'package:storypad/widgets/sp_cross_fade.dart' show SpCrossFade;
import 'package:storypad/widgets/sp_fade_in.dart' show SpFadeIn;
import 'package:storypad/widgets/sp_loop_animation_builder.dart' show SpLoopAnimationBuilder;
import 'package:storypad/widgets/sp_measure_size.dart' show SpMeasureSize;
import 'package:storypad/widgets/sp_tap_effect.dart' show SpTapEffect, SpTapEffectType;
import 'package:storypad/widgets/story_list/sp_story_listener_builder.dart' show SpStoryListenerBuilder;
import 'package:storypad/widgets/story_list/sp_story_tile_list_item.dart' show SpStoryTileListItem;
import 'package:storypad/widgets/story_list/sp_story_list_timeline_verticle_divider.dart'
    show SpSpStoryListTimelineVerticleDivider;

import 'home_view_model.dart';

part 'home_content.dart';
part 'local_widgets/home_scaffold.dart';
part 'local_widgets/home_floating_buttons.dart';
part 'local_widgets/home_app_bar.dart';
part 'local_widgets/home_tab_bar.dart';
part 'local_widgets/home_flexible_space_bar.dart';
part 'local_widgets/home_app_bar_nickname.dart';
part 'local_widgets/home_app_bar_message.dart';
part 'local_widgets/home_empty.dart';
part 'local_widgets/app_update_floating_button.dart';
part 'local_widgets/rounded_indicator.dart';
part 'local_widgets/home_timeline_side_bar.dart';
part 'local_widgets/throwback_tile.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
  });

  static BuildContext? _reloadContext;
  static BuildContext? get reloadContext => _reloadContext;
  static Future<void> reload({
    required String debugSource,
  }) async {
    return _reloadContext?.read<HomeViewModel>().reload(debugSource: debugSource);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<HomeViewModel>(
      create: (context) => HomeViewModel(),
      builder: (context, viewModel, child) {
        _reloadContext = context;

        return DesktopMainMenuPadding(
          child: SpAppLockWrapper(
            child: SpOnboardingWrapper(
              child: _HomeContent(viewModel),
              onOnboarded: () => viewModel.onboard(),
            ),
          ),
        );
      },
    );
  }
}
