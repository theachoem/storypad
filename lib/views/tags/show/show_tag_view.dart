import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_multi_edit_bottom_nav_bar.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
import 'package:storypad/widgets/sp_side_bar_toggler_button.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

import 'show_tag_view_model.dart';

part 'show_tag_content.dart';

class ShowTagRoute extends BaseRoute {
  ShowTagRoute({
    required this.tag,
    required this.storyViewOnly,
  });

  final TagDbModel tag;
  final bool storyViewOnly;

  @override
  Widget buildPage(BuildContext context) => ShowTagView(params: this);

  static String routeName({required int id}) => 'tags/$id';

  @override
  Future<T?> push<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    // - When a SpNestedNavigation exists: use push() so the tag view is stacked locally and the sidebar selection is preserved.
    // - else: use pushNamed() on the [RootView] navigator so the sidebar updates (tag becomes the active selection).
    final nestedNavigator = SpNestedNavigation.maybeOf(context);

    if (nestedNavigator != null) {
      return super.push(context, rootNavigator: rootNavigator);
    } else {
      return Navigator.of(context, rootNavigator: rootNavigator).pushNamed<T>(
        ShowTagRoute.routeName(id: tag.id),
        arguments: this,
      );
    }
  }
}

class ShowTagView extends StatelessWidget {
  const ShowTagView({
    super.key,
    required this.params,
  });

  final ShowTagRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowTagViewModel>(
      create: (context) => ShowTagViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowTagContent(viewModel);
      },
    );
  }
}
