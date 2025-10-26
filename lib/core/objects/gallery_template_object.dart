import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/objects/gallery_template_page_object.dart';

part 'gallery_template_object.g.dart';

@CopyWith()
@JsonSerializable()
class GalleryTemplateObject {
  final String id;
  final String name;
  final String purpose;
  final String? note;
  final List<GalleryTemplatePageObject> pages;
  final String iconUrlPath;

  // this can be loaded later.
  final StoryContentDbModel? lazyDraftContent;

  GalleryTemplateObject({
    required this.id,
    required this.name,
    required this.purpose,
    required this.note,
    required this.pages,
    required this.iconUrlPath,
    this.lazyDraftContent,
  });

  factory GalleryTemplateObject.fromJson(Map<String, dynamic> json) => _$GalleryTemplateObjectFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryTemplateObjectToJson(this);
}
