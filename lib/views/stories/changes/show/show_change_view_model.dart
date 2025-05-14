import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/story_page_objects_map.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';

class ShowChangeViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowChangeRoute params;

  ShowChangeViewModel({
    required this.params,
  }) {
    load();
  }

  StoryPageObjectsMap? pagesMap;

  Future<void> load() async {
    pagesMap = await StoryPageObjectsMap.fromContent(
      content: params.content,
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
