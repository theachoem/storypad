import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'edit_tag_view.dart';

class EditTagViewModel extends ChangeNotifier with DisposeAwareMixin {
  final EditTagRoute params;

  EditTagViewModel({
    required this.params,
  }) : selectedCategoryId = params.tag?.categoryId ?? params.categoryId;

  // null = regular topic tag, TagCategoryDbModel.peopleId = a person.
  int? selectedCategoryId;

  TagDbModel? get tag => params.tag;
  List<String> get tagTitles => params.tags.map((e) => e.title).toList();

  void setCategory(int? categoryId) {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    notifyListeners();
  }
}
