import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_template_page_object.g.dart';

@CopyWith()
@JsonSerializable()
class GalleryTemplatePageObject {
  final String title;
  final String content;

  const GalleryTemplatePageObject({
    required this.title,
    required this.content,
  });

  factory GalleryTemplatePageObject.fromJson(Map<String, dynamic> json) => _$GalleryTemplatePageObjectFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryTemplatePageObjectToJson(this);
}
