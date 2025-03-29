import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/stories/story_content_to_quill_controllers_service.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';

class ShowChangeViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowChangeRoute params;

  ShowChangeViewModel({
    required this.params,
  }) {
    load();
  }

  Map<int, QuillController>? quillControllers;

  Future<void> load() async {
    quillControllers = await StoryContentToQuillControllersService.call(params.content, readOnly: true);
    notifyListeners();
  }

  @override
  void dispose() {
    quillControllers?.forEach((e, k) => k.dispose());
    super.dispose();
  }
}
