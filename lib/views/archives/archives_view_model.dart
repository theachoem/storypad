import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'archives_view.dart';

class ArchivesViewModel extends BaseViewModel {
  final ArchivesRoute params;

  ArchivesViewModel({
    required this.params,
  });

  int editedKey = 0;
  PathType type = PathType.archives;

  void changeEditKey() {
    editedKey++;
    notifyListeners();
  }

  void setType(PathType type) {
    this.type = type;
    notifyListeners();
  }
}
