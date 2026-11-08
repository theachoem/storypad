import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'edit_tag_view.dart';

class EditTagViewModel extends ChangeNotifier with DisposeAwareMixin {
  final EditTagRoute params;

  EditTagViewModel({
    required this.params,
  }) : selectedCategoryId = params.tag?.categoryId ?? params.categoryId,
       selectedColorSeedValue = params.tag?.colorSeedValue;

  // null = regular topic tag, TagCategoryDbModel.peopleId = a person.
  int? selectedCategoryId;

  // null = no color (the default chip).
  int? selectedColorSeedValue;

  TagDbModel? get tag => params.tag;
  List<String> get tagTitles => params.tags.map((e) => e.title).toList();

  void setCategory(int? categoryId) {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Picking the current color again, or black/white (which flips with the theme), clears it.
  void setColor(Color color) {
    final value = color.toARGB32();
    final clear = value == selectedColorSeedValue || value == 0xFF000000 || value == 0xFFFFFFFF;
    selectedColorSeedValue = clear ? null : value;
    notifyListeners();
  }
}
