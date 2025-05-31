import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/providers/theme_provider.dart';
import 'package:storypad/views/stories/local_widgets/manage_pages_button.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_manager.dart';
import 'package:storypad/views/stories/local_widgets/tags_end_drawer.dart';
import 'package:storypad/views/stories/local_widgets/story_end_drawer_button.dart';
import 'package:storypad/views/stories/local_widgets/story_header.dart';
import 'package:storypad/views/stories/local_widgets/story_info_button.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_builder.dart';
import 'package:storypad/views/stories/local_widgets/story_theme_button.dart';
import 'package:storypad/views/theme/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_font_weight_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_fonts_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_quill_toolbar_color_button.dart';
import 'package:storypad/widgets/sp_story_preference_theme.dart';

import 'edit_story_view_model.dart';

part 'edit_story_content.dart';

part 'local_widgets/done_button.dart';
part 'local_widgets/toolbar.dart';
part 'local_widgets/quill_toolbar.dart';
part 'local_widgets/title_toolbar.dart';

class EditStoryRoute extends BaseRoute {
  final int? id;
  final int? initialYear;
  final int? initialMonth;
  final int? initialDay;
  final int? initialTagId;
  final StoryDbModel? story;
  final int? initialPageIndex;
  final double initialPageScrollOffet;
  final StoryPageObjectsMap? pagesMap;

  EditStoryRoute({
    this.id,
    this.initialMonth,
    this.initialYear,
    this.initialDay,
    this.story,
    this.pagesMap,
    this.initialTagId,
    this.initialPageIndex,
    this.initialPageScrollOffet = 0,
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
    if (id != null) return {};

    return {
      'year': initialYear.toString(),
      'month': initialMonth.toString(),
      'day': initialDay.toString(),
      'has_initial_tag': initialTagId != null ? 'true' : 'false',
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
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
          child: SpStoryPreferenceTheme(
            preferences: viewModel.story?.preferences,
            child: _EditStoryContent(viewModel),
          ),
        );
      },
    );
  }
}
