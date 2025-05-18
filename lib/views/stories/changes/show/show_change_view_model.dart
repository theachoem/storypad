import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';

class ShowChangeViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowChangeRoute params;

  ShowChangeViewModel({
    required this.params,
  }) {
    if (content.richPages == null || content.richPages?.isEmpty == true) {
      content = content.addRichPage();
    }

    load();
  }

  late StoryContentDbModel content = params.content;
  StoryPageObjectsMap? pagesMap;

  Future<void> load() async {
    pagesMap = await StoryPageObjectsMap.fromContent(
      content: content,
      readOnly: true,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    pagesMap?.dispose();
    super.dispose();
  }
}
