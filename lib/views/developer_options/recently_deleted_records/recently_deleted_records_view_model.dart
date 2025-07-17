import 'package:flutter/material.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/objectbox.g.dart';
import 'recently_deleted_records_view.dart';

class RecentlyDeletedRecordsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final RecentlyDeletedRecordsRoute params;

  RecentlyDeletedRecordsViewModel({
    required this.params,
  }) {
    load();
  }

  CollectionDbModel<StoryDbModel>? deleteRecords;

  Future<void> load() async {
    deleteRecords = await getDeletedRecords();
    notifyListeners();
  }

  Future<CollectionDbModel<StoryDbModel>?> getDeletedRecords() async {
    final conditions = StoryObjectBox_.permanentlyDeletedAt.notNull().and(StoryObjectBox_.latestContent.notNull());

    QueryBuilder<StoryObjectBox> queryBuilder = StoryDbModel.db.box.query(conditions);

    queryBuilder
      ..order(StoryObjectBox_.year, flags: Order.descending)
      ..order(StoryObjectBox_.month, flags: Order.descending)
      ..order(StoryObjectBox_.day, flags: Order.descending)
      ..order(StoryObjectBox_.hour, flags: Order.descending)
      ..order(StoryObjectBox_.minute, flags: Order.descending);

    Query<StoryObjectBox>? query = queryBuilder.build();
    List<StoryObjectBox> objects = await query.findAsync();

    List<StoryDbModel> docs = await StoryDbModel.db.objectsToModels(objects, {});
    return CollectionDbModel<StoryDbModel>(items: docs);
  }
}
