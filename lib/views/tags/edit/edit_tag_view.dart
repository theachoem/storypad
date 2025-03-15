import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

import 'edit_tag_view_model.dart';

part 'edit_tag_content.dart';

class EditTagRoute extends BaseRoute {
  EditTagRoute({
    required this.tag,
    required this.allTags,
  });

  final TagDbModel? tag;
  final List<TagDbModel> allTags;

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
    return ViewModelProvider<EditTagViewModel>(
      create: (context) => EditTagViewModel(params: params),
      builder: (context, viewModel, child) {
        return _EditTagContent(viewModel);
      },
    );
  }
}
