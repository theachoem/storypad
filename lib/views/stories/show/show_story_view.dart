import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/stories/story_extract_image_from_content_service.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/views/stories/local_widgets/story_header.dart';
import 'package:storypad/views/stories/local_widgets/tags_end_drawer.dart';
import 'package:storypad/widgets/custom_embed/date_block_embed.dart';
import 'package:storypad/widgets/custom_embed/image_block_embed.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/story_list/story_info_sheet.dart';

import 'show_story_view_model.dart';

part 'show_story_content.dart';

class ShowStoryRoute extends BaseRoute {
  final int id;
  final StoryDbModel? story;

  ShowStoryRoute({
    required this.id,
    required this.story,
  });

  @override
  Widget buildPage(BuildContext context) => ShowStoryView(params: this);
}

class ShowStoryView extends StatelessWidget {
  const ShowStoryView({
    super.key,
    required this.params,
  });

  final ShowStoryRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowStoryViewModel>(
      create: (context) => ShowStoryViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _ShowStoryContent(viewModel);
      },
    );
  }
}
