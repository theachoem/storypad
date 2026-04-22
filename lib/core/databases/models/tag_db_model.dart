import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/tags_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/services/tag_id_generator_service.dart';

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
  final String? emoji;
  final DateTime createdAt;
  final int? categoryId;

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
    required this.emoji,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
    required this.permanentlyDeletedAt,
    int? index,
  }) : index = index ?? 0;

  bool get feeling => categoryId == TagCategoryDbModel.feeling().id;

  TagDbModel.fromIDTitle(this.id, this.title)
    : version = 0,
      emoji = null,
      categoryId = null,
      index = 0,
      createdAt = DateTime.now(),
      updatedAt = DateTime.now(),
      lastSavedDeviceId = null,
      permanentlyDeletedAt = null;

  factory TagDbModel.emoji(
    String emoji, {
    required int categoryId,
  }) {
    return TagDbModel(
      id: TagIdGeneratorService.emojiId(emoji),
      version: 0,
      title: "Emoji",
      emoji: emoji,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
    );
  }

  factory TagDbModel.fromNow() {
    return TagDbModel(
      id: TagIdGeneratorService.timeId(),
      version: 0,
      title: 'Favorite',
      emoji: null,
      categoryId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      permanentlyDeletedAt: null,
      lastSavedDeviceId: null,
    );
  }

  Future<void> save() async {
    await db.set(
      this,
      debugSource: '$runtimeType#save',
    );
  }

  bool exist() => db.exist(id);

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
