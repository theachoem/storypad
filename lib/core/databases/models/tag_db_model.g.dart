// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TagDbModelCWProxy {
  TagDbModel id(int id);

  TagDbModel version(int version);

  TagDbModel title(String title);

  TagDbModel starred(bool? starred);

  TagDbModel emoji(String? emoji);

  TagDbModel createdAt(DateTime createdAt);

  TagDbModel updatedAt(DateTime updatedAt);

  TagDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  TagDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  TagDbModel index(int? index);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TagDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TagDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  TagDbModel call({
    int id,
    int version,
    String title,
    bool? starred,
    String? emoji,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    int? index,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTagDbModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTagDbModel.copyWith.fieldName(...)`
class _$TagDbModelCWProxyImpl implements _$TagDbModelCWProxy {
  const _$TagDbModelCWProxyImpl(this._value);

  final TagDbModel _value;

  @override
  TagDbModel id(int id) => this(id: id);

  @override
  TagDbModel version(int version) => this(version: version);

  @override
  TagDbModel title(String title) => this(title: title);

  @override
  TagDbModel starred(bool? starred) => this(starred: starred);

  @override
  TagDbModel emoji(String? emoji) => this(emoji: emoji);

  @override
  TagDbModel createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  TagDbModel updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  TagDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      this(lastSavedDeviceId: lastSavedDeviceId);

  @override
  TagDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      this(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  TagDbModel index(int? index) => this(index: index);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TagDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TagDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  TagDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? starred = const $CopyWithPlaceholder(),
    Object? emoji = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? index = const $CopyWithPlaceholder(),
  }) {
    return TagDbModel(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      starred: starred == const $CopyWithPlaceholder()
          ? _value.starred
          // ignore: cast_nullable_to_non_nullable
          : starred as bool?,
      emoji: emoji == const $CopyWithPlaceholder()
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String?,
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

extension $TagDbModelCopyWith on TagDbModel {
  /// Returns a callable class that can be used as follows: `instanceOfTagDbModel.copyWith(...)` or like so:`instanceOfTagDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TagDbModelCWProxy get copyWith => _$TagDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagDbModel _$TagDbModelFromJson(Map<String, dynamic> json) => TagDbModel(
      id: (json['id'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      title: json['title'] as String,
      starred: json['starred'] as bool?,
      emoji: json['emoji'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
      index: (json['index'] as num?)?.toInt(),
    )..storiesCount = (json['stories_count'] as num?)?.toInt();

Map<String, dynamic> _$TagDbModelToJson(TagDbModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'index': instance.index,
      'version': instance.version,
      'title': instance.title,
      'starred': instance.starred,
      'emoji': instance.emoji,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_saved_device_id': instance.lastSavedDeviceId,
      'permanently_deleted_at':
          instance.permanentlyDeletedAt?.toIso8601String(),
      'stories_count': instance.storiesCount,
    };
