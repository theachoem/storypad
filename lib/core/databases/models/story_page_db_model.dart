import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'story_page_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class StoryPageDbModel {
  final String? title;

  // only use when passing data.
  // we don't store plainText here. Instead we story in story content.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? plainText;

  // List: Returns JSON-serializable version of quill delta.
  final List<dynamic>? body;

  StoryPageDbModel({
    required this.title,
    required this.body,
    this.plainText,
  });

  Map<String, dynamic> toJson() => _$StoryPageDbModelToJson(this);
  factory StoryPageDbModel.fromJson(Map<String, dynamic> json) => _$StoryPageDbModelFromJson(json);
}
