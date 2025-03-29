import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'tags_view.dart';

class TagsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TagsRoute params;

  TagsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    context.read<TagsProvider>().reload();
  }

  bool get checkable => params.initialSelectedTags != null && params.onToggleTags != null;
  late List<int> selectedTags = params.initialSelectedTags ?? [];

  Future<void> onToggle(TagDbModel tag, bool value) async {
    HapticFeedback.selectionClick();

    if (value == true) {
      selectedTags = {...selectedTags, tag.id}.toList();
      notifyListeners();

      bool success = await params.onToggleTags!(selectedTags);
      if (!success) {
        selectedTags = params.initialSelectedTags ?? [];
        notifyListeners();
      }
    } else if (value == false) {
      selectedTags = selectedTags.toList()..removeWhere((id) => id == tag.id);
      notifyListeners();

      bool success = await params.onToggleTags!(selectedTags);
      if (!success) {
        selectedTags = params.initialSelectedTags ?? [];
        notifyListeners();
      }
    }
  }
}
