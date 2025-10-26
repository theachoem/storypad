import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';

part 'gallery_template_category_object.g.dart';

@CopyWith()
@JsonSerializable()
class GalleryTemplateCategoryObject {
  final String name;
  final String description;
  final List<GalleryTemplateObject> templates;

  const GalleryTemplateCategoryObject({
    required this.name,
    required this.description,
    required this.templates,
  });

  factory GalleryTemplateCategoryObject.fromJson(Map<String, dynamic> json) =>
      _$GalleryTemplateCategoryObjectFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryTemplateCategoryObjectToJson(this);
}
