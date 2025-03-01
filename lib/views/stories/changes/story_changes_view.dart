import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/sp_multi_edit_bottom_nav_bar.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/routes/base_route.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

import 'story_changes_view_model.dart';

part 'story_changes_content.dart';

class StoryChangesRoute extends BaseRoute {
  final int id;

  StoryChangesRoute({
    required this.id,
  });

  @override
  Widget buildPage(BuildContext context) => StoryChangesView(params: this);
}

class StoryChangesView extends StatelessWidget {
  const StoryChangesView({
    super.key,
    required this.params,
  });

  final StoryChangesRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<StoryChangesViewModel>(
      create: (context) => StoryChangesViewModel(params: params),
      builder: (context, viewModel, child) {
        return _StoryChangesContent(viewModel);
      },
    );
  }
}
