import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

import 'tags_view_model.dart';

part 'tags_content.dart';

class TagsRoute extends BaseRoute {
  static const String routeName = 'tags';

  final bool storyViewOnly;
  final List<int>? initialSelectedTags;
  final Future<bool> Function(List<int> selectedTags)? onToggleTags;

  TagsRoute({
    this.storyViewOnly = false,
    this.initialSelectedTags,
    this.onToggleTags,
  });

  @override
  Widget buildPage(BuildContext context) => TagsView(params: this);

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
        TagsRoute.routeName,
        arguments: this,
      );
    }
  }
}

class TagsView extends StatelessWidget {
  const TagsView({
    super.key,
    required this.params,
  });

  final TagsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<TagsViewModel>(
      create: (context) => TagsViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _TagsContent(viewModel);
      },
    );
  }
}
