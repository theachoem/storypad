import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'tags_view.dart';

class TagsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TagsRoute params;
  late final TagsProvider tagsProvider;

  TagsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    tagsProvider = context.read<TagsProvider>();
    load();
  }

  Map<int, int> storiesCountByTagId = {};
  int getStoriesCount(TagDbModel tag) => storiesCountByTagId[tag.id] ?? 0;

  Future<void> load() async {
    await tagsProvider.reload();
    storiesCountByTagId = StoryDbModel.db.getStoryCountByTags(
      tagIds: tagsProvider.tags?.items.map((e) => e.id).toList() ?? [],
    );
    notifyListeners();
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
