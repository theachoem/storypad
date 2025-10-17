import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/events_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';

part 'event_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class EventDbModel extends BaseDbModel {
  static final EventsBox db = EventsBox();

  @override
  final int id;

  final int year;
  final int month;
  final int day;
  final String eventType;

  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  final String? lastSavedDeviceId;

  @override
  final DateTime? permanentlyDeletedAt;

  EventDbModel({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.eventType,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.permanentlyDeletedAt,
    this.lastSavedDeviceId,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get period => eventType == 'period';
  DateTime? get date => DateTime(year, month, day);

  Future<EventDbModel?> createIfNotExist() async {
    final existingEvents = await db.where(
      filters: {
        "year": year,
        "month": month,
        "day": day,
        "event_type": eventType,
      },
    );

    if (existingEvents?.items.isNotEmpty == true) return null;
    return db.create(this);
  }

  factory EventDbModel.period({
    required DateTime date,
  }) {
    final now = DateTime.now();
    return EventDbModel(
      id: DateTime.now().millisecondsSinceEpoch,
      year: date.year,
      month: date.month,
      day: date.day,
      eventType: 'period',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory EventDbModel.fromJson(Map<String, dynamic> json) => _$EventDbModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EventDbModelToJson(this);

  bool _cloudViewing = false;
  bool get cloudViewing => _cloudViewing;

  EventDbModel markAsCloudViewing() {
    _cloudViewing = true;
    return this;
  }
}
