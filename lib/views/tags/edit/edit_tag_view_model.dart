import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'edit_tag_view.dart';

class EditTagViewModel extends ChangeNotifier with DisposeAwareMixin {
  final EditTagRoute params;

  EditTagViewModel({
    required this.params,
  });

  TagDbModel? get tag => params.tag;
  List<String> get tagTitles => params.allTags.map((e) => e.title).toList();

  bool isTagExist(String title) {
    return tagTitles.map((e) => e.toLowerCase()).contains(title.trim().toLowerCase());
  }
}
