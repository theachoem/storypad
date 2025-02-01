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

  StoryDbModel showDayCount(bool? showDayCount);

  StoryDbModel year(int year);

  StoryDbModel month(int month);

  StoryDbModel day(int day);

  StoryDbModel hour(int? hour);

  StoryDbModel minute(int? minute);

  StoryDbModel second(int? second);

  StoryDbModel updatedAt(DateTime updatedAt);

  StoryDbModel createdAt(DateTime createdAt);

  StoryDbModel tags(List<String>? tags);

  StoryDbModel movedToBinAt(DateTime? movedToBinAt);

  StoryDbModel allChanges(List<StoryContentDbModel>? allChanges);

  StoryDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  StoryDbModel rawChanges(List<String>? rawChanges);

  StoryDbModel latestChange(StoryContentDbModel? latestChange);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryDbModel call({
    int version,
    PathType type,
    int id,
    bool? starred,
    String? feeling,
    bool? showDayCount,
    int year,
    int month,
    int day,
    int? hour,
    int? minute,
    int? second,
    DateTime updatedAt,
    DateTime createdAt,
    List<String>? tags,
    DateTime? movedToBinAt,
    List<StoryContentDbModel>? allChanges,
    String? lastSavedDeviceId,
    List<String>? rawChanges,
    StoryContentDbModel? latestChange,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStoryDbModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStoryDbModel.copyWith.fieldName(...)`
class _$StoryDbModelCWProxyImpl implements _$StoryDbModelCWProxy {
  const _$StoryDbModelCWProxyImpl(this._value);

  final StoryDbModel _value;

  @override
  StoryDbModel version(int version) => this(version: version);

  @override
  StoryDbModel type(PathType type) => this(type: type);

  @override
  StoryDbModel id(int id) => this(id: id);

  @override
  StoryDbModel starred(bool? starred) => this(starred: starred);

  @override
  StoryDbModel feeling(String? feeling) => this(feeling: feeling);

  @override
  StoryDbModel showDayCount(bool? showDayCount) =>
      this(showDayCount: showDayCount);

  @override
  StoryDbModel year(int year) => this(year: year);

  @override
  StoryDbModel month(int month) => this(month: month);

  @override
  StoryDbModel day(int day) => this(day: day);

  @override
  StoryDbModel hour(int? hour) => this(hour: hour);

  @override
  StoryDbModel minute(int? minute) => this(minute: minute);

  @override
  StoryDbModel second(int? second) => this(second: second);

  @override
  StoryDbModel updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  StoryDbModel createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  StoryDbModel tags(List<String>? tags) => this(tags: tags);

  @override
  StoryDbModel movedToBinAt(DateTime? movedToBinAt) =>
      this(movedToBinAt: movedToBinAt);

  @override
  StoryDbModel allChanges(List<StoryContentDbModel>? allChanges) =>
      this(allChanges: allChanges);

  @override
  StoryDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      this(lastSavedDeviceId: lastSavedDeviceId);

  @override
  StoryDbModel rawChanges(List<String>? rawChanges) =>
      this(rawChanges: rawChanges);

  @override
  StoryDbModel latestChange(StoryContentDbModel? latestChange) =>
      this(latestChange: latestChange);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryDbModel call({
    Object? version = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? starred = const $CopyWithPlaceholder(),
    Object? feeling = const $CopyWithPlaceholder(),
    Object? showDayCount = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
    Object? month = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
    Object? hour = const $CopyWithPlaceholder(),
    Object? minute = const $CopyWithPlaceholder(),
    Object? second = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? movedToBinAt = const $CopyWithPlaceholder(),
    Object? allChanges = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? rawChanges = const $CopyWithPlaceholder(),
    Object? latestChange = const $CopyWithPlaceholder(),
  }) {
    return StoryDbModel(
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PathType,
      id: id == const $CopyWithPlaceholder()
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
      showDayCount: showDayCount == const $CopyWithPlaceholder()
          ? _value.showDayCount
          // ignore: cast_nullable_to_non_nullable
          : showDayCount as bool?,
      year: year == const $CopyWithPlaceholder()
          ? _value.year
          // ignore: cast_nullable_to_non_nullable
          : year as int,
      month: month == const $CopyWithPlaceholder()
          ? _value.month
          // ignore: cast_nullable_to_non_nullable
          : month as int,
      day: day == const $CopyWithPlaceholder()
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
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>?,
      movedToBinAt: movedToBinAt == const $CopyWithPlaceholder()
          ? _value.movedToBinAt
          // ignore: cast_nullable_to_non_nullable
          : movedToBinAt as DateTime?,
      allChanges: allChanges == const $CopyWithPlaceholder()
          ? _value.allChanges
          // ignore: cast_nullable_to_non_nullable
          : allChanges as List<StoryContentDbModel>?,
      lastSavedDeviceId: lastSavedDeviceId == const $CopyWithPlaceholder()
          ? _value.lastSavedDeviceId
          // ignore: cast_nullable_to_non_nullable
          : lastSavedDeviceId as String?,
      rawChanges: rawChanges == const $CopyWithPlaceholder()
          ? _value.rawChanges
          // ignore: cast_nullable_to_non_nullable
          : rawChanges as List<String>?,
      latestChange: latestChange == const $CopyWithPlaceholder()
          ? _value.latestChange
          // ignore: cast_nullable_to_non_nullable
          : latestChange as StoryContentDbModel?,
    );
  }
}

extension $StoryDbModelCopyWith on StoryDbModel {
  /// Returns a callable class that can be used as follows: `instanceOfStoryDbModel.copyWith(...)` or like so:`instanceOfStoryDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryDbModelCWProxy get copyWith => _$StoryDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryDbModel _$StoryDbModelFromJson(Map<String, dynamic> json) => StoryDbModel(
      version: (json['version'] as num?)?.toInt() ?? 1,
      type: $enumDecode(_$PathTypeEnumMap, json['type']),
      id: (json['id'] as num).toInt(),
      starred: json['starred'] as bool?,
      feeling: json['feeling'] as String?,
      showDayCount: json['show_day_count'] as bool?,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      day: (json['day'] as num).toInt(),
      hour: (json['hour'] as num?)?.toInt(),
      minute: (json['minute'] as num?)?.toInt(),
      second: (json['second'] as num?)?.toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: tagsFromJson(json['tags']),
      movedToBinAt: json['moved_to_bin_at'] == null
          ? null
          : DateTime.parse(json['moved_to_bin_at'] as String),
      allChanges: (json['changes'] as List<dynamic>?)
          ?.map((e) => StoryContentDbModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
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
      'changes': instance.allChanges?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'moved_to_bin_at': instance.movedToBinAt?.toIso8601String(),
      'last_saved_device_id': instance.lastSavedDeviceId,
      'show_day_count': instance.showDayCount,
    };

const _$PathTypeEnumMap = {
  PathType.docs: 'docs',
  PathType.bins: 'bins',
  PathType.archives: 'archives',
};
