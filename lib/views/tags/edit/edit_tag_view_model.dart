import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'edit_tag_view.dart';

class EditTagViewModel extends BaseViewModel {
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
