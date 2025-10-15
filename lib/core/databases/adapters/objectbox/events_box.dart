import 'dart:isolate';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/objectbox.g.dart';

class EventsBox extends BaseBox<EventObjectBox, EventDbModel> {
  @override
  String get tableName => "events";

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    Condition<EventObjectBox>? conditions = EventObjectBox_.id.notNull();

    if (fromThisDeviceOnly == true) {
      conditions.and(EventObjectBox_.lastSavedDeviceId.equals(kDeviceInfo.id));
    }

    Query<EventObjectBox> query = box
        .query(conditions)
        .order(EventObjectBox_.updatedAt, flags: Order.descending)
        .build();
    EventObjectBox? object = await query.findFirstAsync();

    return object?.updatedAt;
  }

  @override
  Future<void> cleanupOldDeletedRecords() async {
    DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    Condition<EventObjectBox> conditions = EventObjectBox_.permanentlyDeletedAt.notNull().and(
      EventObjectBox_.permanentlyDeletedAt.lessOrEqualDate(sevenDaysAgo),
    );
    await box.query(conditions).build().removeAsync();
  }

  @override
  QueryBuilder<EventObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? order = filters?["order"];
    int? month = filters?["month"];
    int? day = filters?["day"];
    int? year = filters?["year"];
    String? eventType = filters?["event_type"];

    Condition<EventObjectBox>? conditions = EventObjectBox_.id.notNull();

    if (!returnDeleted) conditions = conditions.and(EventObjectBox_.permanentlyDeletedAt.isNull());
    if (year != null) conditions = conditions.and(EventObjectBox_.year.equals(year));
    if (month != null) conditions = conditions.and(EventObjectBox_.month.equals(month));
    if (day != null) conditions = conditions.and(EventObjectBox_.day.equals(day));
    if (eventType != null) conditions = conditions.and(EventObjectBox_.eventType.equals(eventType));

    QueryBuilder<EventObjectBox> queryBuilder = box.query(conditions);

    // null mean asc which is default.
    if (order != null) {
      queryBuilder
        ..order(EventObjectBox_.year, flags: order)
        ..order(EventObjectBox_.month, flags: order)
        ..order(EventObjectBox_.day, flags: order);
    }

    return queryBuilder;
  }

  @override
  Future<EventObjectBox> modelToObject(EventDbModel model, [Map<String, dynamic>? options]) async {
    return _modelToObject(model, options);
  }

  @override
  Future<EventDbModel> objectToModel(EventObjectBox object, [Map<String, dynamic>? options]) async {
    return _objectToModel(object, options);
  }

  @override
  Future<List<EventObjectBox>> modelsToObjects(List<EventDbModel> models, [Map<String, dynamic>? options]) async {
    return Isolate.run(() => models.map((model) => _modelToObject(model, options)).toList());
  }

  @override
  Future<List<EventDbModel>> objectsToModels(List<EventObjectBox> objects, [Map<String, dynamic>? options]) async {
    return Isolate.run(() => objects.map((object) => _objectToModel(object, options)).toList());
  }

  @override
  EventDbModel modelFromJson(Map<String, dynamic> json) {
    return EventDbModel.fromJson(json);
  }
}

EventObjectBox _modelToObject(EventDbModel model, [Map<String, dynamic>? options]) {
  return EventObjectBox(
    id: model.id,
    year: model.year,
    month: model.month,
    day: model.day,
    eventType: model.eventType,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
    permanentlyDeletedAt: model.permanentlyDeletedAt,
    lastSavedDeviceId: kDeviceInfo.id,
  );
}

EventDbModel _objectToModel(EventObjectBox object, [Map<String, dynamic>? options]) {
  return EventDbModel(
    id: object.id,
    year: object.year,
    month: object.month,
    day: object.day,
    eventType: object.eventType,
    createdAt: object.createdAt,
    updatedAt: object.updatedAt,
    permanentlyDeletedAt: object.permanentlyDeletedAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
  );
}
