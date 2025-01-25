import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'show_tag_view.dart';

class ShowTagViewModel extends BaseViewModel {
  final ShowTagRoute params;

  ShowTagViewModel({
    required this.params,
  });

  TagDbModel get tag => params.tag;
}
