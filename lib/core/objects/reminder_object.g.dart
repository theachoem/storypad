// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReminderObjectCWProxy {
  ReminderObject id(int id);

  ReminderObject type(ReminderType type);

  ReminderObject enabled(bool enabled);

  ReminderObject hour(int hour);

  ReminderObject minute(int minute);

  ReminderObject weekdays(List<int> weekdays);

  ReminderObject message(String? message);

  ReminderObject templateId(int? templateId);

  ReminderObject galleryTemplateId(String? galleryTemplateId);

  ReminderObject tagIds(List<int>? tagIds);

  ReminderObject daysAhead(int? daysAhead);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ReminderObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReminderObject(...).copyWith(id: 12, name: "My name")
  /// ```
  ReminderObject call({
    int id,
    ReminderType type,
    bool enabled,
    int hour,
    int minute,
    List<int> weekdays,
    String? message,
    int? templateId,
    String? galleryTemplateId,
    List<int>? tagIds,
    int? daysAhead,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReminderObject.copyWith(...)` or call `instanceOfReminderObject.copyWith.fieldName(value)` for a single field.
class _$ReminderObjectCWProxyImpl implements _$ReminderObjectCWProxy {
  const _$ReminderObjectCWProxyImpl(this._value);

  final ReminderObject _value;

  @override
  ReminderObject id(int id) => call(id: id);

  @override
  ReminderObject type(ReminderType type) => call(type: type);

  @override
  ReminderObject enabled(bool enabled) => call(enabled: enabled);

  @override
  ReminderObject hour(int hour) => call(hour: hour);

  @override
  ReminderObject minute(int minute) => call(minute: minute);

  @override
  ReminderObject weekdays(List<int> weekdays) => call(weekdays: weekdays);

  @override
  ReminderObject message(String? message) => call(message: message);

  @override
  ReminderObject templateId(int? templateId) => call(templateId: templateId);

  @override
  ReminderObject galleryTemplateId(String? galleryTemplateId) =>
      call(galleryTemplateId: galleryTemplateId);

  @override
  ReminderObject tagIds(List<int>? tagIds) => call(tagIds: tagIds);

  @override
  ReminderObject daysAhead(int? daysAhead) => call(daysAhead: daysAhead);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ReminderObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReminderObject(...).copyWith(id: 12, name: "My name")
  /// ```
  ReminderObject call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? hour = const $CopyWithPlaceholder(),
    Object? minute = const $CopyWithPlaceholder(),
    Object? weekdays = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? templateId = const $CopyWithPlaceholder(),
    Object? galleryTemplateId = const $CopyWithPlaceholder(),
    Object? tagIds = const $CopyWithPlaceholder(),
    Object? daysAhead = const $CopyWithPlaceholder(),
  }) {
    return ReminderObject(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ReminderType,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      hour: hour == const $CopyWithPlaceholder() || hour == null
          ? _value.hour
          // ignore: cast_nullable_to_non_nullable
          : hour as int,
      minute: minute == const $CopyWithPlaceholder() || minute == null
          ? _value.minute
          // ignore: cast_nullable_to_non_nullable
          : minute as int,
      weekdays: weekdays == const $CopyWithPlaceholder() || weekdays == null
          ? _value.weekdays
          // ignore: cast_nullable_to_non_nullable
          : weekdays as List<int>,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String?,
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as int?,
      galleryTemplateId: galleryTemplateId == const $CopyWithPlaceholder()
          ? _value.galleryTemplateId
          // ignore: cast_nullable_to_non_nullable
          : galleryTemplateId as String?,
      tagIds: tagIds == const $CopyWithPlaceholder()
          ? _value.tagIds
          // ignore: cast_nullable_to_non_nullable
          : tagIds as List<int>?,
      daysAhead: daysAhead == const $CopyWithPlaceholder()
          ? _value.daysAhead
          // ignore: cast_nullable_to_non_nullable
          : daysAhead as int?,
    );
  }
}

extension $ReminderObjectCopyWith on ReminderObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReminderObject.copyWith(...)` or `instanceOfReminderObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReminderObjectCWProxy get copyWith => _$ReminderObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReminderObject _$ReminderObjectFromJson(Map<String, dynamic> json) =>
    ReminderObject(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(
        _$ReminderTypeEnumMap,
        json['type'],
        unknownValue: ReminderType.custom,
      ),
      enabled: json['enabled'] as bool? ?? true,
      hour: (json['hour'] as num?)?.toInt() ?? 21,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      weekdays:
          (json['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      message: json['message'] as String?,
      templateId: (json['template_id'] as num?)?.toInt(),
      galleryTemplateId: json['gallery_template_id'] as String?,
      tagIds: (json['tag_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      daysAhead: (json['days_ahead'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ReminderObjectToJson(ReminderObject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ReminderTypeEnumMap[instance.type]!,
      'enabled': instance.enabled,
      'hour': instance.hour,
      'minute': instance.minute,
      'weekdays': instance.weekdays,
      'message': instance.message,
      'template_id': instance.templateId,
      'gallery_template_id': instance.galleryTemplateId,
      'tag_ids': instance.tagIds,
      'days_ahead': instance.daysAhead,
    };

const _$ReminderTypeEnumMap = {
  ReminderType.daily: 'daily',
  ReminderType.onThisDay: 'onThisDay',
  ReminderType.period: 'period',
  ReminderType.custom: 'custom',
};
