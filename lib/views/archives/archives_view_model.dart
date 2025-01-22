import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'archives_view.dart';

class ArchivesViewModel extends BaseViewModel {
  final ArchivesRoute params;

  ArchivesViewModel({
    required this.params,
  });

  PathType type = PathType.archives;

  void setType(PathType type) {
    this.type = type;
    notifyListeners();
  }
}
