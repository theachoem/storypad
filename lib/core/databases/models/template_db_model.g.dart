// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateDbModelCWProxy {
  TemplateDbModel id(int id);

  TemplateDbModel tags(List<int>? tags);

  TemplateDbModel content(StoryContentDbModel? content);

  TemplateDbModel preferences(StoryPreferencesDbModel? preferences);

  TemplateDbModel createdAt(DateTime createdAt);

  TemplateDbModel updatedAt(DateTime updatedAt);

  TemplateDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  TemplateDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  TemplateDbModel index(int? index);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateDbModel call({
    int id,
    List<int>? tags,
    StoryContentDbModel? content,
    StoryPreferencesDbModel? preferences,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    int? index,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTemplateDbModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTemplateDbModel.copyWith.fieldName(...)`
class _$TemplateDbModelCWProxyImpl implements _$TemplateDbModelCWProxy {
  const _$TemplateDbModelCWProxyImpl(this._value);

  final TemplateDbModel _value;

  @override
  TemplateDbModel id(int id) => this(id: id);

  @override
  TemplateDbModel tags(List<int>? tags) => this(tags: tags);

  @override
  TemplateDbModel content(StoryContentDbModel? content) =>
      this(content: content);

  @override
  TemplateDbModel preferences(StoryPreferencesDbModel? preferences) =>
      this(preferences: preferences);

  @override
  TemplateDbModel createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  TemplateDbModel updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  TemplateDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      this(lastSavedDeviceId: lastSavedDeviceId);

  @override
  TemplateDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      this(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  TemplateDbModel index(int? index) => this(index: index);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TemplateDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TemplateDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  TemplateDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
    Object? preferences = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? index = const $CopyWithPlaceholder(),
  }) {
    return TemplateDbModel(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<int>?,
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as StoryContentDbModel?,
      preferences: preferences == const $CopyWithPlaceholder()
          ? _value.preferences
          // ignore: cast_nullable_to_non_nullable
          : preferences as StoryPreferencesDbModel?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      lastSavedDeviceId: lastSavedDeviceId == const $CopyWithPlaceholder()
          ? _value.lastSavedDeviceId
          // ignore: cast_nullable_to_non_nullable
          : lastSavedDeviceId as String?,
      permanentlyDeletedAt: permanentlyDeletedAt == const $CopyWithPlaceholder()
          ? _value.permanentlyDeletedAt
          // ignore: cast_nullable_to_non_nullable
          : permanentlyDeletedAt as DateTime?,
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int?,
    );
  }
}

extension $TemplateDbModelCopyWith on TemplateDbModel {
  /// Returns a callable class that can be used as follows: `instanceOfTemplateDbModel.copyWith(...)` or like so:`instanceOfTemplateDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateDbModelCWProxy get copyWith => _$TemplateDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateDbModel _$TemplateDbModelFromJson(Map<String, dynamic> json) =>
    TemplateDbModel(
      id: (json['id'] as num).toInt(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      content: json['content'] == null
          ? null
          : StoryContentDbModel.fromJson(
              json['content'] as Map<String, dynamic>),
      preferences: json['preferences'] == null
          ? null
          : StoryPreferencesDbModel.fromJson(
              json['preferences'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
      index: (json['index'] as num?)?.toInt(),
    )..storiesCount = (json['stories_count'] as num?)?.toInt();

Map<String, dynamic> _$TemplateDbModelToJson(TemplateDbModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'index': instance.index,
      'tags': instance.tags,
      'preferences': instance.preferences.toJson(),
      'content': instance.content?.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_saved_device_id': instance.lastSavedDeviceId,
      'permanently_deleted_at':
          instance.permanentlyDeletedAt?.toIso8601String(),
      'stories_count': instance.storiesCount,
    };
