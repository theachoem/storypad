// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_category_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TagCategoryDbModelCWProxy {
  TagCategoryDbModel id(int id);

  TagCategoryDbModel version(int version);

  TagCategoryDbModel multiSelect(bool multiSelect);

  TagCategoryDbModel createdAt(DateTime createdAt);

  TagCategoryDbModel updatedAt(DateTime updatedAt);

  TagCategoryDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  TagCategoryDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  TagCategoryDbModel index(int? index);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TagCategoryDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TagCategoryDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  TagCategoryDbModel call({
    int id,
    int version,
    bool multiSelect,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    int? index,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTagCategoryDbModel.copyWith(...)` or call `instanceOfTagCategoryDbModel.copyWith.fieldName(value)` for a single field.
class _$TagCategoryDbModelCWProxyImpl implements _$TagCategoryDbModelCWProxy {
  const _$TagCategoryDbModelCWProxyImpl(this._value);

  final TagCategoryDbModel _value;

  @override
  TagCategoryDbModel id(int id) => call(id: id);

  @override
  TagCategoryDbModel version(int version) => call(version: version);

  @override
  TagCategoryDbModel multiSelect(bool multiSelect) =>
      call(multiSelect: multiSelect);

  @override
  TagCategoryDbModel createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  @override
  TagCategoryDbModel updatedAt(DateTime updatedAt) =>
      call(updatedAt: updatedAt);

  @override
  TagCategoryDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  TagCategoryDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  TagCategoryDbModel index(int? index) => call(index: index);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TagCategoryDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TagCategoryDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  TagCategoryDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? multiSelect = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? index = const $CopyWithPlaceholder(),
  }) {
    return TagCategoryDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      title: _value._title,
      multiSelect:
          multiSelect == const $CopyWithPlaceholder() || multiSelect == null
          ? _value.multiSelect
          // ignore: cast_nullable_to_non_nullable
          : multiSelect as bool,
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
      index: index == const $CopyWithPlaceholder()
          ? _value.index
          // ignore: cast_nullable_to_non_nullable
          : index as int?,
    );
  }
}

extension $TagCategoryDbModelCopyWith on TagCategoryDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTagCategoryDbModel.copyWith(...)` or `instanceOfTagCategoryDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TagCategoryDbModelCWProxy get copyWith =>
      _$TagCategoryDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagCategoryDbModel _$TagCategoryDbModelFromJson(Map<String, dynamic> json) =>
    TagCategoryDbModel(
      id: (json['id'] as num).toInt(),
      version: (json['version'] as num).toInt(),
      title: json['title'] as String,
      multiSelect: json['multi_select'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
      index: (json['index'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TagCategoryDbModelToJson(
  TagCategoryDbModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'version': instance.version,
  'multi_select': instance.multiSelect,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'last_saved_device_id': instance.lastSavedDeviceId,
  'permanently_deleted_at': instance.permanentlyDeletedAt?.toIso8601String(),
  'title': instance.title,
};
