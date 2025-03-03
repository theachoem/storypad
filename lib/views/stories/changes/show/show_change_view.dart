import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/stories/story_extract_image_from_content_service.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';
import 'package:storypad/widgets/custom_embed/date_block_embed.dart';
import 'package:storypad/widgets/custom_embed/image_block_embed.dart';

import 'show_change_view_model.dart';

part 'show_change_content.dart';

class ShowChangeRoute extends BaseRoute {
  ShowChangeRoute({
    required this.content,
  });

  final StoryContentDbModel content;

  @override
  Widget buildPage(BuildContext context) => ShowChangeView(params: this);
}

class ShowChangeView extends StatelessWidget {
  const ShowChangeView({
    super.key,
    required this.params,
  });

  final ShowChangeRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowChangeViewModel>(
      create: (context) => ShowChangeViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowChangeContent(viewModel);
      },
    );
  }
}
