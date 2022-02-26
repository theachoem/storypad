import 'package:spooky/core/file_manager/story_writers/objects/default_story_object.dart';
import 'package:spooky/ui/views/detail/detail_view_model_getter.dart';

class DeleteChangeObject extends DefaultStoryObject {
  final List<String> contentIds;

  DeleteChangeObject(
    DetailViewModelGetter info, {
    required this.contentIds,
  }) : super(info);
}
