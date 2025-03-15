import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/sp_cross_fade.dart';
import 'package:storypad/widgets/sp_multi_edit_bottom_nav_bar.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/story_list/story_list.dart';
import 'package:storypad/widgets/story_list/story_list_multi_edit_wrapper.dart';

import 'archives_view_model.dart';

part 'archives_content.dart';

class ArchivesRoute extends BaseRoute {
  @override
  Widget buildPage(BuildContext context) => ArchivesView(params: this);
}

class ArchivesView extends StatelessWidget {
  const ArchivesView({
    super.key,
    required this.params,
  });

  final ArchivesRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ArchivesViewModel>(
      create: (context) => ArchivesViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ArchivesContent(viewModel);
      },
    );
  }
}
