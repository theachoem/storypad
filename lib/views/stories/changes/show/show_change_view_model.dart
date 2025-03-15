import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/services/stories/story_content_to_quill_controllers_service.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';

class ShowChangeViewModel extends BaseViewModel {
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
