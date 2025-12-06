import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/storages/new_badge_storage.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/views/tags/show/show_tag_view.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_onboarding_wrapper.dart';
import 'package:storypad/widgets/sp_side_bar_toggler_button.dart';

import 'root_view_model.dart';

part 'root_content.dart';
part 'local_widgets/root_route_observer.dart';
part 'local_widgets/tag_header.dart';
part 'local_widgets/side_bar.dart';
part 'local_widgets/side_bar_item.dart';

class RootView extends StatelessWidget {
  const RootView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<RootViewModel>(
      create: (context) => RootViewModel(),
      builder: (context, viewModel, child) {
        return _RootContent(viewModel);
      },
    );
  }
}
