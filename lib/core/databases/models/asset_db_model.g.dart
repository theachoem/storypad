// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AssetDbModelCWProxy {
  AssetDbModel id(int id);

  AssetDbModel originalSource(String originalSource);

  AssetDbModel cloudDestinations(
    Map<String, Map<String, Map<String, String>>> cloudDestinations,
  );

  AssetDbModel createdAt(DateTime createdAt);

  AssetDbModel updatedAt(DateTime updatedAt);

  AssetDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  AssetDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  AssetDbModel type(AssetType type);

  AssetDbModel tags(List<int>? tags);

  AssetDbModel metadata(Map<String, dynamic>? metadata);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `AssetDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AssetDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  AssetDbModel call({
    int id,
    String originalSource,
    Map<String, Map<String, Map<String, String>>> cloudDestinations,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    AssetType type,
    List<int>? tags,
    Map<String, dynamic>? metadata,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAssetDbModel.copyWith(...)` or call `instanceOfAssetDbModel.copyWith.fieldName(value)` for a single field.
class _$AssetDbModelCWProxyImpl implements _$AssetDbModelCWProxy {
  const _$AssetDbModelCWProxyImpl(this._value);

  final AssetDbModel _value;

  @override
  AssetDbModel id(int id) => call(id: id);

  @override
  AssetDbModel originalSource(String originalSource) =>
      call(originalSource: originalSource);

  @override
  AssetDbModel cloudDestinations(
    Map<String, Map<String, Map<String, String>>> cloudDestinations,
  ) => call(cloudDestinations: cloudDestinations);

  @override
  AssetDbModel createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  AssetDbModel updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  AssetDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  AssetDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  AssetDbModel type(AssetType type) => call(type: type);

  @override
  AssetDbModel tags(List<int>? tags) => call(tags: tags);

  @override
  AssetDbModel metadata(Map<String, dynamic>? metadata) =>
      call(metadata: metadata);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `AssetDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AssetDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  AssetDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? originalSource = const $CopyWithPlaceholder(),
    Object? cloudDestinations = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? metadata = const $CopyWithPlaceholder(),
  }) {
    return AssetDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      originalSource:
          originalSource == const $CopyWithPlaceholder() ||
              originalSource == null
          ? _value.originalSource
          // ignore: cast_nullable_to_non_nullable
          : originalSource as String,
      cloudDestinations:
          cloudDestinations == const $CopyWithPlaceholder() ||
              cloudDestinations == null
          ? _value.cloudDestinations
          // ignore: cast_nullable_to_non_nullable
          : cloudDestinations as Map<String, Map<String, Map<String, String>>>,
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
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as AssetType,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<int>?,
      metadata: metadata == const $CopyWithPlaceholder()
          ? _value.metadata
          // ignore: cast_nullable_to_non_nullable
          : metadata as Map<String, dynamic>?,
    );
  }
}

extension $AssetDbModelCopyWith on AssetDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAssetDbModel.copyWith(...)` or `instanceOfAssetDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AssetDbModelCWProxy get copyWith => _$AssetDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetDbModel _$AssetDbModelFromJson(Map<String, dynamic> json) => AssetDbModel(
  id: (json['id'] as num).toInt(),
  originalSource: json['original_source'] as String,
  cloudDestinations: (json['cloud_destinations'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      (e as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Map<String, String>.from(e as Map)),
      ),
    ),
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  lastSavedDeviceId: json['last_saved_device_id'] as String?,
  permanentlyDeletedAt: json['permanently_deleted_at'] == null
      ? null
      : DateTime.parse(json['permanently_deleted_at'] as String),
  type: _assetTypeFromJson(json['type'] as String?),
  tags: (json['tags'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AssetDbModelToJson(
  AssetDbModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'original_source': instance.originalSource,
  'tags': instance.tags,
  'cloud_destinations': instance.cloudDestinations,
  'type': _assetTypeToJson(instance.type),
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'last_saved_device_id': instance.lastSavedDeviceId,
  'permanently_deleted_at': instance.permanentlyDeletedAt?.toIso8601String(),
};
