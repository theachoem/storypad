import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/tags_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';

part 'tag_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class TagDbModel extends BaseDbModel {
  static final TagsBox db = TagsBox();

  @override
  final int id;
  final int index;
  final int version;
  final String title;
  final bool? starred;
  final String? emoji;
  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  @override
  final DateTime? permanentlyDeletedAt;

  int? storiesCount;

  TagDbModel({
    required this.id,
    required this.version,
    required this.title,
    required this.starred,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
    int? index,
  }) : index = index ?? 0;

  TagDbModel.fromIDTitle(this.id, this.title)
      : version = 0,
        starred = null,
        emoji = null,
        index = 0,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        lastSavedDeviceId = null,
        permanentlyDeletedAt = null;

  factory TagDbModel.fromNow() {
    return TagDbModel(
      id: 0,
      version: 0,
      title: 'Favorite',
      starred: true,
      emoji: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSavedDeviceId: null,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$TagDbModelToJson(this);
  factory TagDbModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('index')) json['index'] = 0;
    return _$TagDbModelFromJson(json);
  }

  bool _cloudViewing = false;
  bool get cloudViewing => _cloudViewing;
  TagDbModel markAsCloudViewing() {
    _cloudViewing = true;
    return this;
  }
}
