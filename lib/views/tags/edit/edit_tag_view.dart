import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

import 'edit_tag_view_model.dart';

part 'edit_tag_content.dart';

/// Result returned by the edit/new tag page: the title plus the chosen category
/// (null = a regular topic tag, [TagCategoryDbModel.peopleId] = a person).
class EditTagResult {
  const EditTagResult({required this.title, required this.categoryId});

  final String title;
  final int? categoryId;
}

class EditTagRoute extends BaseRoute {
  EditTagRoute({
    required this.tag,
    required this.tags,
    this.categoryId,
  });

  final TagDbModel? tag;
  final List<TagDbModel> tags;

  /// Initial category for the selector. Defaults to the editing tag's category.
  final int? categoryId;

  @override
  String get className => tag == null ? 'NewTagRoute' : 'EditTagRoute';

  @override
  Widget buildPage(BuildContext context) => EditTagView(params: this);
}

class EditTagView extends StatelessWidget {
  const EditTagView({
    super.key,
    required this.params,
  });

  final EditTagRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditTagViewModel>(
      create: (context) => EditTagViewModel(params: params),
      builder: (context, child) {
        return _EditTagContent(Provider.of(context));
      },
    );
  }
}
