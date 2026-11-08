// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TagDbModelCWProxy {
  TagDbModel id(int id);

  TagDbModel version(int version);

  TagDbModel title(String title);

  TagDbModel emoji(String? emoji);

  TagDbModel categoryId(int? categoryId);

  TagDbModel createdAt(DateTime createdAt);

  TagDbModel updatedAt(DateTime updatedAt);

  TagDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  TagDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  TagDbModel colorSeedValue(int? colorSeedValue);

  TagDbModel index(int? index);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TagDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TagDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  TagDbModel call({
    int id,
    int version,
    String title,
    String? emoji,
    int? categoryId,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    int? colorSeedValue,
    int? index,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTagDbModel.copyWith(...)` or call `instanceOfTagDbModel.copyWith.fieldName(value)` for a single field.
class _$TagDbModelCWProxyImpl implements _$TagDbModelCWProxy {
  const _$TagDbModelCWProxyImpl(this._value);

  final TagDbModel _value;

  @override
  TagDbModel id(int id) => call(id: id);

  @override
  TagDbModel version(int version) => call(version: version);

  @override
  TagDbModel title(String title) => call(title: title);

  @override
  TagDbModel emoji(String? emoji) => call(emoji: emoji);

  @override
  TagDbModel categoryId(int? categoryId) => call(categoryId: categoryId);

  @override
  TagDbModel createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  TagDbModel updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  TagDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  TagDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  TagDbModel colorSeedValue(int? colorSeedValue) =>
      call(colorSeedValue: colorSeedValue);

  @override
  TagDbModel index(int? index) => call(index: index);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TagDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TagDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TagDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? emoji = const $CopyWithPlaceholder(),
    Object? categoryId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? colorSeedValue = const $CopyWithPlaceholder(),
    Object? index = const $CopyWithPlaceholder(),
  }) {
    return TagDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      emoji: emoji == const $CopyWithPlaceholder()
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String?,
      categoryId: categoryId == const $CopyWithPlaceholder()
          ? _value.categoryId
          // ignore: cast_nullable_to_non_nullable
          : categoryId as int?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
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
      colorSeedValue: colorSeedValue == const $CopyWithPlaceholder()
          ? _value.colorSeedValue
          // ignore: cast_nullable_to_non_nullable
          : colorSeedValue as int?,
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int?,
    );
  }
}

extension $TagDbModelCopyWith on TagDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTagDbModel.copyWith(...)` or `instanceOfTagDbModel.copyWith.fieldName(...)`.
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
  emoji: json['emoji'] as String?,
  categoryId: (json['category_id'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  lastSavedDeviceId: json['last_saved_device_id'] as String?,
  permanentlyDeletedAt: json['permanently_deleted_at'] == null
      ? null
      : DateTime.parse(json['permanently_deleted_at'] as String),
  colorSeedValue: (json['color_seed_value'] as num?)?.toInt(),
  index: (json['index'] as num?)?.toInt(),
)..storiesCount = (json['stories_count'] as num?)?.toInt();

Map<String, dynamic> _$TagDbModelToJson(
  TagDbModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'version': instance.version,
  'title': instance.title,
  'emoji': instance.emoji,
  'created_at': instance.createdAt.toIso8601String(),
  'category_id': instance.categoryId,
  'color_seed_value': instance.colorSeedValue,
  'updated_at': instance.updatedAt.toIso8601String(),
  'last_saved_device_id': instance.lastSavedDeviceId,
  'permanently_deleted_at': instance.permanentlyDeletedAt?.toIso8601String(),
  'stories_count': instance.storiesCount,
};
