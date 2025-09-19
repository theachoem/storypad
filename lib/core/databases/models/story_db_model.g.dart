// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryDbModelCWProxy {
  StoryDbModel version(int version);

  StoryDbModel type(PathType type);

  StoryDbModel id(int id);

  StoryDbModel starred(bool? starred);

  StoryDbModel feeling(String? feeling);

  StoryDbModel year(int year);

  StoryDbModel month(int month);

  StoryDbModel day(int day);

  StoryDbModel hour(int? hour);

  StoryDbModel minute(int? minute);

  StoryDbModel second(int? second);

  StoryDbModel updatedAt(DateTime updatedAt);

  StoryDbModel createdAt(DateTime createdAt);

  StoryDbModel preferences(StoryPreferencesDbModel? preferences);

  StoryDbModel tags(List<String>? tags);

  StoryDbModel assets(List<int>? assets);

  StoryDbModel movedToBinAt(DateTime? movedToBinAt);

  StoryDbModel latestContent(StoryContentDbModel? latestContent);

  StoryDbModel draftContent(StoryContentDbModel? draftContent);

  StoryDbModel templateId(int? templateId);

  StoryDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  StoryDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryDbModel call({
    int version,
    PathType type,
    int id,
    bool? starred,
    String? feeling,
    int year,
    int month,
    int day,
    int? hour,
    int? minute,
    int? second,
    DateTime updatedAt,
    DateTime createdAt,
    StoryPreferencesDbModel? preferences,
    List<String>? tags,
    List<int>? assets,
    DateTime? movedToBinAt,
    StoryContentDbModel? latestContent,
    StoryContentDbModel? draftContent,
    int? templateId,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStoryDbModel.copyWith(...)` or call `instanceOfStoryDbModel.copyWith.fieldName(value)` for a single field.
class _$StoryDbModelCWProxyImpl implements _$StoryDbModelCWProxy {
  const _$StoryDbModelCWProxyImpl(this._value);

  final StoryDbModel _value;

  @override
  StoryDbModel version(int version) => call(version: version);

  @override
  StoryDbModel type(PathType type) => call(type: type);

  @override
  StoryDbModel id(int id) => call(id: id);

  @override
  StoryDbModel starred(bool? starred) => call(starred: starred);

  @override
  StoryDbModel feeling(String? feeling) => call(feeling: feeling);

  @override
  StoryDbModel year(int year) => call(year: year);

  @override
  StoryDbModel month(int month) => call(month: month);

  @override
  StoryDbModel day(int day) => call(day: day);

  @override
  StoryDbModel hour(int? hour) => call(hour: hour);

  @override
  StoryDbModel minute(int? minute) => call(minute: minute);

  @override
  StoryDbModel second(int? second) => call(second: second);

  @override
  StoryDbModel updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  StoryDbModel createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  StoryDbModel preferences(StoryPreferencesDbModel? preferences) =>
      call(preferences: preferences);

  @override
  StoryDbModel tags(List<String>? tags) => call(tags: tags);

  @override
  StoryDbModel assets(List<int>? assets) => call(assets: assets);

  @override
  StoryDbModel movedToBinAt(DateTime? movedToBinAt) =>
      call(movedToBinAt: movedToBinAt);

  @override
  StoryDbModel latestContent(StoryContentDbModel? latestContent) =>
      call(latestContent: latestContent);

  @override
  StoryDbModel draftContent(StoryContentDbModel? draftContent) =>
      call(draftContent: draftContent);

  @override
  StoryDbModel templateId(int? templateId) => call(templateId: templateId);

  @override
  StoryDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  StoryDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryDbModel call({
    Object? version = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? starred = const $CopyWithPlaceholder(),
    Object? feeling = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
    Object? month = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
    Object? hour = const $CopyWithPlaceholder(),
    Object? minute = const $CopyWithPlaceholder(),
    Object? second = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? preferences = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? assets = const $CopyWithPlaceholder(),
    Object? movedToBinAt = const $CopyWithPlaceholder(),
    Object? latestContent = const $CopyWithPlaceholder(),
    Object? draftContent = const $CopyWithPlaceholder(),
    Object? templateId = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
  }) {
    return StoryDbModel(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PathType,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      starred: starred == const $CopyWithPlaceholder()
          ? _value.starred
          // ignore: cast_nullable_to_non_nullable
          : starred as bool?,
      feeling: feeling == const $CopyWithPlaceholder()
          ? _value.feeling
          // ignore: cast_nullable_to_non_nullable
          : feeling as String?,
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
      hour: hour == const $CopyWithPlaceholder()
          ? _value.hour
          // ignore: cast_nullable_to_non_nullable
          : hour as int?,
      minute: minute == const $CopyWithPlaceholder()
          ? _value.minute
          // ignore: cast_nullable_to_non_nullable
          : minute as int?,
      second: second == const $CopyWithPlaceholder()
          ? _value.second
          // ignore: cast_nullable_to_non_nullable
          : second as int?,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      preferences: preferences == const $CopyWithPlaceholder()
          ? _value.preferences
          // ignore: cast_nullable_to_non_nullable
          : preferences as StoryPreferencesDbModel?,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>?,
      assets: assets == const $CopyWithPlaceholder()
          ? _value.assets
          // ignore: cast_nullable_to_non_nullable
          : assets as List<int>?,
      movedToBinAt: movedToBinAt == const $CopyWithPlaceholder()
          ? _value.movedToBinAt
          // ignore: cast_nullable_to_non_nullable
          : movedToBinAt as DateTime?,
      latestContent: latestContent == const $CopyWithPlaceholder()
          ? _value.latestContent
          // ignore: cast_nullable_to_non_nullable
          : latestContent as StoryContentDbModel?,
      draftContent: draftContent == const $CopyWithPlaceholder()
          ? _value.draftContent
          // ignore: cast_nullable_to_non_nullable
          : draftContent as StoryContentDbModel?,
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as int?,
      lastSavedDeviceId: lastSavedDeviceId == const $CopyWithPlaceholder()
          ? _value.lastSavedDeviceId
          // ignore: cast_nullable_to_non_nullable
          : lastSavedDeviceId as String?,
      permanentlyDeletedAt: permanentlyDeletedAt == const $CopyWithPlaceholder()
          ? _value.permanentlyDeletedAt
          // ignore: cast_nullable_to_non_nullable
          : permanentlyDeletedAt as DateTime?,
    );
  }
}

extension $StoryDbModelCopyWith on StoryDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStoryDbModel.copyWith(...)` or `instanceOfStoryDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryDbModelCWProxy get copyWith => _$StoryDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryDbModel _$StoryDbModelFromJson(Map<String, dynamic> json) => StoryDbModel(
      version: (json['version'] as num?)?.toInt() ?? 2,
      type: $enumDecode(_$PathTypeEnumMap, json['type']),
      id: (json['id'] as num).toInt(),
      starred: json['starred'] as bool?,
      feeling: json['feeling'] as String?,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      day: (json['day'] as num).toInt(),
      hour: (json['hour'] as num?)?.toInt(),
      minute: (json['minute'] as num?)?.toInt(),
      second: (json['second'] as num?)?.toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      preferences: json['preferences'] == null
          ? null
          : StoryPreferencesDbModel.fromJson(
              json['preferences'] as Map<String, dynamic>),
      tags: tagsFromJson(json['tags']),
      assets: (json['assets'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      movedToBinAt: json['moved_to_bin_at'] == null
          ? null
          : DateTime.parse(json['moved_to_bin_at'] as String),
      latestContent: json['latest_content'] == null
          ? null
          : StoryContentDbModel.fromJson(
              json['latest_content'] as Map<String, dynamic>),
      draftContent: json['draft_content'] == null
          ? null
          : StoryContentDbModel.fromJson(
              json['draft_content'] as Map<String, dynamic>),
      templateId: (json['template_id'] as num?)?.toInt(),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
    );

Map<String, dynamic> _$StoryDbModelToJson(StoryDbModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'type': _$PathTypeEnumMap[instance.type]!,
      'year': instance.year,
      'month': instance.month,
      'day': instance.day,
      'hour': instance.hour,
      'minute': instance.minute,
      'second': instance.second,
      'starred': instance.starred,
      'feeling': instance.feeling,
      'tags': instance.tags,
      'assets': instance.assets,
      'latest_content': instance.latestContent?.toJson(),
      'draft_content': instance.draftContent?.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'template_id': instance.templateId,
      'moved_to_bin_at': instance.movedToBinAt?.toIso8601String(),
      'last_saved_device_id': instance.lastSavedDeviceId,
      'preferences': instance.preferences.toJson(),
      'permanently_deleted_at':
          instance.permanentlyDeletedAt?.toIso8601String(),
    };

const _$PathTypeEnumMap = {
  PathType.docs: 'docs',
  PathType.bins: 'bins',
  PathType.archives: 'archives',
};
