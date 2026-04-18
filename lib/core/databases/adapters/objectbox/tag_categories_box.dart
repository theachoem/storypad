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

  Future<Map<TagCategoryDbModel, List<TagDbModel>>> getSuggestTagsByCategory({
    Set<int>? selectedTagIds,
  }) async {
    List<TagCategoryDbModel> categories = TagCategoryDbModel.systemCategories;

    Future<List<TagDbModel>> getTagsForCategory(TagCategoryDbModel category) async {
      final existing = await TagDbModel.db
          .where(filters: {'category_id': category.id})
          .then((e) => e?.items ?? <TagDbModel>[]);

      final suggested = category.suggestTags();
      final suggestedEmojiSet = suggested.map((tag) => tag.emoji).whereType<String>().toSet();

      final existingByEmoji = {
        for (final tag in existing)
          if (tag.emoji != null) tag.emoji!: tag,
      };

      // Always show all suggested emojis first, in the defined category order.
      // If a suggested emoji already exists in this category, reuse the existing DB tag.
      final orderedSuggested = <TagDbModel>[];
      for (final tag in suggested) {
        final emoji = tag.emoji;
        if (emoji == null) continue;

        final existingTag = existingByEmoji.remove(emoji);
        if (existingTag != null) {
          orderedSuggested.add(existingTag);
        } else {
          orderedSuggested.add(tag);
        }
      }

      // Append only selected non-suggested stickers.
      final selectedExtras = existing.where((tag) {
        final selected = selectedTagIds?.contains(tag.id) == true;
        if (!selected) return false;

        final emoji = tag.emoji;
        return emoji == null || !suggestedEmojiSet.contains(emoji);
      });

      return [
        ...orderedSuggested,
        ...selectedExtras,
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
