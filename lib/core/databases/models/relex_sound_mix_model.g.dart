// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relex_sound_mix_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelaxSoundMixModelCWProxy {
  RelaxSoundMixModel id(int id);

  RelaxSoundMixModel name(String name);

  RelaxSoundMixModel sounds(List<RelaxSoundModel> sounds);

  RelaxSoundMixModel createdAt(DateTime createdAt);

  RelaxSoundMixModel updatedAt(DateTime updatedAt);

  RelaxSoundMixModel lastSavedDeviceId(String? lastSavedDeviceId);

  RelaxSoundMixModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  RelaxSoundMixModel index(int? index);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundMixModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundMixModel(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundMixModel call({
    int id,
    String name,
    List<RelaxSoundModel> sounds,
    DateTime createdAt,
    DateTime updatedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    int? index,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRelaxSoundMixModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRelaxSoundMixModel.copyWith.fieldName(...)`
class _$RelaxSoundMixModelCWProxyImpl implements _$RelaxSoundMixModelCWProxy {
  const _$RelaxSoundMixModelCWProxyImpl(this._value);

  final RelaxSoundMixModel _value;

  @override
  RelaxSoundMixModel id(int id) => this(id: id);

  @override
  RelaxSoundMixModel name(String name) => this(name: name);

  @override
  RelaxSoundMixModel sounds(List<RelaxSoundModel> sounds) =>
      this(sounds: sounds);

  @override
  RelaxSoundMixModel createdAt(DateTime createdAt) =>
      this(createdAt: createdAt);

  @override
  RelaxSoundMixModel updatedAt(DateTime updatedAt) =>
      this(updatedAt: updatedAt);

  @override
  RelaxSoundMixModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      this(lastSavedDeviceId: lastSavedDeviceId);

  @override
  RelaxSoundMixModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      this(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  RelaxSoundMixModel index(int? index) => this(index: index);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundMixModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundMixModel(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundMixModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? sounds = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? index = const $CopyWithPlaceholder(),
  }) {
    return RelaxSoundMixModel(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      sounds: sounds == const $CopyWithPlaceholder()
          ? _value.sounds
          // ignore: cast_nullable_to_non_nullable
          : sounds as List<RelaxSoundModel>,
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

extension $RelaxSoundMixModelCopyWith on RelaxSoundMixModel {
  /// Returns a callable class that can be used as follows: `instanceOfRelaxSoundMixModel.copyWith(...)` or like so:`instanceOfRelaxSoundMixModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelaxSoundMixModelCWProxy get copyWith =>
      _$RelaxSoundMixModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelaxSoundMixModel _$RelaxSoundMixModelFromJson(Map<String, dynamic> json) =>
    RelaxSoundMixModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sounds: (json['sounds'] as List<dynamic>)
          .map((e) => RelaxSoundModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
      index: (json['index'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RelaxSoundMixModelToJson(RelaxSoundMixModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'index': instance.index,
      'name': instance.name,
      'sounds': instance.sounds.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'permanently_deleted_at':
          instance.permanentlyDeletedAt?.toIso8601String(),
      'last_saved_device_id': instance.lastSavedDeviceId,
    };
