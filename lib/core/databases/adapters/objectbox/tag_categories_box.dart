import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/objectbox.g.dart';

part './helpers/tag_categories_box_transformer.dart';

class TagCategoriesBox extends BaseBox<TagCategoryObjectBox, TagCategoryDbModel> {
  @override
  String get tableName => "tag_categories";

  @override
  QueryIntegerProperty<TagCategoryObjectBox> get idProperty => TagCategoryObjectBox_.id;

  @override
  QueryStringProperty<TagCategoryObjectBox> get lastSavedDeviceIdProperty => TagCategoryObjectBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<TagCategoryObjectBox> get permanentlyDeletedAtProperty =>
      TagCategoryObjectBox_.permanentlyDeletedAt;

  // newly suggest tags can be already used by user with different suggested category,
  // so in that case, we don't need to suggest it again, keep user's existing tags in the category they want.
  Future<Map<TagCategoryDbModel, List<TagDbModel>>>? getAllTagsByCategory() async {
    List<TagCategoryDbModel> categories = [
      TagCategoryDbModel.feeling(),
      TagCategoryDbModel.activity(),
    ];

    final usedEmojis = TagDbModel.db.box
        .query(TagObjectBox_.emoji.notNull())
        .build()
        .property(TagObjectBox_.emoji)
        .find()
        .toSet();

    Future<List<TagDbModel>> getTagsForCategory(TagCategoryDbModel category) async {
      final existing = await TagDbModel.db
          .where(filters: {'category_id': category.id})
          .then((e) => e?.items ?? <TagDbModel>[]);

      final suggestions = category.suggestTags().where((tag) {
        final emoji = tag.emoji;
        return emoji != null && !usedEmojis.contains(emoji);
      });

      return [
        ...suggestions,
        ...existing,
      ];
    }

    return {
      for (var category in categories) category: await getTagsForCategory(category),
    };
  }

  @override
  QueryBuilder<TagCategoryObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];
    int? order = filters?["order"];

    Condition<TagCategoryObjectBox> conditions = TagCategoryObjectBox_.id.notNull();
    if (!returnDeleted) conditions = conditions.and(TagCategoryObjectBox_.permanentlyDeletedAt.isNull());
    if (createdYear != null) {
      conditions = conditions.and(
        TagCategoryObjectBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

    QueryBuilder<TagCategoryObjectBox> queryBuilder = box.query(conditions);

    queryBuilder.order(TagCategoryObjectBox_.index, flags: order ?? 0);

    return queryBuilder;
  }

  @override
  TagCategoryDbModel modelFromJson(Map<String, dynamic> json) {
    return TagCategoryDbModel.fromJson(json);
  }

  @override
  Future<List<TagCategoryDbModel>> objectsToModels(
    List<TagCategoryObjectBox> objects, [
    Map<String, dynamic>? options,
  ]) {
    return compute(_objectsToModels, {'objects': objects, 'options': options});
  }

  @override
  Future<List<TagCategoryObjectBox>> modelsToObjects(List<TagCategoryDbModel> models, [Map<String, dynamic>? options]) {
    return compute(_modelsToObjects, {'models': models, 'options': options});
  }

  @override
  Future<TagCategoryObjectBox> modelToObject(TagCategoryDbModel model, [Map<String, dynamic>? options]) {
    return compute(_modelToObject, {'model': model, 'options': options});
  }

  @override
  Future<TagCategoryDbModel> objectToModel(TagCategoryObjectBox object, [Map<String, dynamic>? options]) {
    return compute(_objectToModel, {'object': object, 'options': options});
  }
}
