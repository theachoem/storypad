// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EventDbModelCWProxy {
  EventDbModel id(int id);

  EventDbModel year(int year);

  EventDbModel month(int month);

  EventDbModel day(int day);

  EventDbModel eventType(String eventType);

  EventDbModel createdAt(DateTime? createdAt);

  EventDbModel updatedAt(DateTime? updatedAt);

  EventDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  EventDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `EventDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EventDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  EventDbModel call({
    int id,
    int year,
    int month,
    int day,
    String eventType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? permanentlyDeletedAt,
    String? lastSavedDeviceId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEventDbModel.copyWith(...)` or call `instanceOfEventDbModel.copyWith.fieldName(value)` for a single field.
class _$EventDbModelCWProxyImpl implements _$EventDbModelCWProxy {
  const _$EventDbModelCWProxyImpl(this._value);

  final EventDbModel _value;

  @override
  EventDbModel id(int id) => call(id: id);

  @override
  EventDbModel year(int year) => call(year: year);

  @override
  EventDbModel month(int month) => call(month: month);

  @override
  EventDbModel day(int day) => call(day: day);

  @override
  EventDbModel eventType(String eventType) => call(eventType: eventType);

  @override
  EventDbModel createdAt(DateTime? createdAt) => call(createdAt: createdAt);

  @override
  EventDbModel updatedAt(DateTime? updatedAt) => call(updatedAt: updatedAt);

  @override
  EventDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  EventDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `EventDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EventDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  EventDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
    Object? month = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
    Object? eventType = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
  }) {
    return EventDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      year: year == const $CopyWithPlaceholder() || year == null
          ? _value.year
          // ignore: cast_nullable_to_non_nullable
          : year as int,
      month: month == const $CopyWithPlaceholder() || month == null
          ? _value.month
          // ignore: cast_nullable_to_non_nullable
          : month as int,
      day: day == const $CopyWithPlaceholder() || day == null
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as int,
      eventType: eventType == const $CopyWithPlaceholder() || eventType == null
          ? _value.eventType
          // ignore: cast_nullable_to_non_nullable
          : eventType as String,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime?,
      permanentlyDeletedAt: permanentlyDeletedAt == const $CopyWithPlaceholder()
          ? _value.permanentlyDeletedAt
          // ignore: cast_nullable_to_non_nullable
          : permanentlyDeletedAt as DateTime?,
      lastSavedDeviceId: lastSavedDeviceId == const $CopyWithPlaceholder()
          ? _value.lastSavedDeviceId
          // ignore: cast_nullable_to_non_nullable
          : lastSavedDeviceId as String?,
    );
  }
}

extension $EventDbModelCopyWith on EventDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEventDbModel.copyWith(...)` or `instanceOfEventDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EventDbModelCWProxy get copyWith => _$EventDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventDbModel _$EventDbModelFromJson(Map<String, dynamic> json) => EventDbModel(
  id: (json['id'] as num).toInt(),
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  day: (json['day'] as num).toInt(),
  eventType: json['event_type'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  permanentlyDeletedAt: json['permanently_deleted_at'] == null
      ? null
      : DateTime.parse(json['permanently_deleted_at'] as String),
  lastSavedDeviceId: json['last_saved_device_id'] as String?,
);

Map<String, dynamic> _$EventDbModelToJson(
  EventDbModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'year': instance.year,
  'month': instance.month,
  'day': instance.day,
  'event_type': instance.eventType,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'last_saved_device_id': instance.lastSavedDeviceId,
  'permanently_deleted_at': instance.permanentlyDeletedAt?.toIso8601String(),
};
