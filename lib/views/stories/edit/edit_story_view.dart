import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/helpers/quill_context_menu_helper.dart';
import 'package:storypad/core/services/stories/story_extract_image_from_content_service.dart';
import 'package:storypad/widgets/sp_quill_unknown_embed_builder.dart';
import 'package:storypad/widgets/sp_sliver_sticky_divider.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/image_picker_service.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/views/stories/local_widgets/story_header.dart';
import 'package:storypad/views/stories/local_widgets/tags_end_drawer.dart';
import 'package:storypad/widgets/custom_embed/date_block_embed.dart';
import 'package:storypad/widgets/custom_embed/image_block_embed.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_quill_toolbar_color_button.dart';

import 'edit_story_view_model.dart';

part 'edit_story_content.dart';
part 'local_widgets/editor.dart';
part 'local_widgets/focus_node_builder.dart';

class EditStoryRoute extends BaseRoute {
  final int? id;
  final int? initialYear;
  final int initialPageIndex;
  final Map<int, QuillController>? quillControllers;
  final StoryDbModel? story;

  EditStoryRoute({
    this.id,
    this.initialYear,
    this.initialPageIndex = 0,
    this.quillControllers,
    this.story,
  }) : assert(initialYear == null || id == null);

  @override
  String get className {
    if (id == null) {
      return "NewStoryRoute";
    } else {
      return "EditStoryRoute";
    }
  }

  @override
  Map<String, String?> get analyticsParameters {
    return {
      'flow_type': id == null ? 'new' : 'edit',
    };
  }

  @override
  Widget buildPage(BuildContext context) => EditStoryView(params: this);
}

class EditStoryView extends StatelessWidget {
  const EditStoryView({
    super.key,
    required this.params,
  });

  final EditStoryRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<EditStoryViewModel>(
      create: (context) => EditStoryViewModel(params: params),
      builder: (context, viewModel, child) {
        return _EditStoryContent(viewModel);
      },
    );
  }
}
