// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PreferenceDbModelCWProxy {
  PreferenceDbModel id(int id);

  PreferenceDbModel key(String key);

  PreferenceDbModel value(String value);

  PreferenceDbModel createdAt(DateTime createdAt);

  PreferenceDbModel updatedAt(DateTime updatedAt);

  PreferenceDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  PreferenceDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PreferenceDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PreferenceDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  PreferenceDbModel call({
    int id,
    String key,
    String value,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPreferenceDbModel.copyWith(...)` or call `instanceOfPreferenceDbModel.copyWith.fieldName(value)` for a single field.
class _$PreferenceDbModelCWProxyImpl implements _$PreferenceDbModelCWProxy {
  const _$PreferenceDbModelCWProxyImpl(this._value);

  final PreferenceDbModel _value;

  @override
  PreferenceDbModel id(int id) => call(id: id);

  @override
  PreferenceDbModel key(String key) => call(key: key);

  @override
  PreferenceDbModel value(String value) => call(value: value);

  @override
  PreferenceDbModel createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  PreferenceDbModel updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  PreferenceDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  PreferenceDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PreferenceDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PreferenceDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  PreferenceDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
  }) {
    return PreferenceDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
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
    );
  }
}

extension $PreferenceDbModelCopyWith on PreferenceDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPreferenceDbModel.copyWith(...)` or `instanceOfPreferenceDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PreferenceDbModelCWProxy get copyWith =>
      _$PreferenceDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreferenceDbModel _$PreferenceDbModelFromJson(Map<String, dynamic> json) =>
    PreferenceDbModel(
      id: (json['id'] as num).toInt(),
      key: json['key'] as String,
      value: json['value'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
    );

Map<String, dynamic> _$PreferenceDbModelToJson(PreferenceDbModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'value': instance.value,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_saved_device_id': instance.lastSavedDeviceId,
      'permanently_deleted_at':
          instance.permanentlyDeletedAt?.toIso8601String(),
    };
