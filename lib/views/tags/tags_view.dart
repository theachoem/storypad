import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_scroll_configuration.dart';

import 'tags_view_model.dart';

part 'tags_content.dart';

class TagsRoute extends BaseRoute {
  @override
  String get routeName => 'tags';

  final bool storyViewOnly;
  final List<int>? initialSelectedTags;
  final double? bottomPadding;
  final Future<bool> Function(List<int> selectedTags)? onToggleTags;

  TagsRoute({
    this.storyViewOnly = false,
    this.initialSelectedTags,
    this.onToggleTags,
    this.bottomPadding,
  });

  @override
  Widget buildPage(BuildContext context) => TagsView(params: this);
}

class TagsView extends StatelessWidget {
  const TagsView({
    super.key,
    required this.params,
  });

  final TagsRoute params;

  bool get _checkable => params.initialSelectedTags != null && params.onToggleTags != null;

  @override
  Widget build(BuildContext context) {
    final content = ViewModelProvider<TagsViewModel>(
      create: (context) => TagsViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _TagsContent(viewModel);
      },
    );

    if (_checkable) return content;

    return Scaffold(
      appBar: AppBar(title: Text(tr('page.tags.title'))),
      body: content,
    );
  }
}
