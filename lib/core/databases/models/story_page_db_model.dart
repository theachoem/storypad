import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'story_page_db_model.g.dart';

int _idFromJson(dynamic id) {
  if (id is int) {
    return id;
  } else {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

@CopyWith()
@JsonSerializable()
class StoryPageDbModel {
  @JsonKey(fromJson: _idFromJson)
  final int id;
  final String? title;

  // List: Returns JSON-serializable version of quill delta.
  final List<dynamic>? body;

  StoryPageDbModel({
    required this.id,
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toJson() => _$StoryPageDbModelToJson(this);
  factory StoryPageDbModel.fromJson(Map<String, dynamic> json) => _$StoryPageDbModelFromJson(json);
}
