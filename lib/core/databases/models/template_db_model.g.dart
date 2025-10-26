// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateDbModelCWProxy {
  TemplateDbModel id(int id);

  TemplateDbModel tags(List<int>? tags);

  TemplateDbModel name(String? name);

  TemplateDbModel content(StoryContentDbModel? content);

  TemplateDbModel galleryTemplateId(String? galleryTemplateId);

  TemplateDbModel note(String? note);

  TemplateDbModel preferences(StoryPreferencesDbModel? preferences);

  TemplateDbModel createdAt(DateTime createdAt);

  TemplateDbModel updatedAt(DateTime updatedAt);

  TemplateDbModel archivedAt(DateTime? archivedAt);

  TemplateDbModel lastSavedDeviceId(String? lastSavedDeviceId);

  TemplateDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt);

  TemplateDbModel index(int? index);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TemplateDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  TemplateDbModel call({
    int id,
    List<int>? tags,
    String? name,
    StoryContentDbModel? content,
    String? galleryTemplateId,
    String? note,
    StoryPreferencesDbModel? preferences,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime? archivedAt,
    String? lastSavedDeviceId,
    DateTime? permanentlyDeletedAt,
    int? index,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTemplateDbModel.copyWith(...)` or call `instanceOfTemplateDbModel.copyWith.fieldName(value)` for a single field.
class _$TemplateDbModelCWProxyImpl implements _$TemplateDbModelCWProxy {
  const _$TemplateDbModelCWProxyImpl(this._value);

  final TemplateDbModel _value;

  @override
  TemplateDbModel id(int id) => call(id: id);

  @override
  TemplateDbModel tags(List<int>? tags) => call(tags: tags);

  @override
  TemplateDbModel name(String? name) => call(name: name);

  @override
  TemplateDbModel content(StoryContentDbModel? content) =>
      call(content: content);

  @override
  TemplateDbModel galleryTemplateId(String? galleryTemplateId) =>
      call(galleryTemplateId: galleryTemplateId);

  @override
  TemplateDbModel note(String? note) => call(note: note);

  @override
  TemplateDbModel preferences(StoryPreferencesDbModel? preferences) =>
      call(preferences: preferences);

  @override
  TemplateDbModel createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  TemplateDbModel updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  TemplateDbModel archivedAt(DateTime? archivedAt) =>
      call(archivedAt: archivedAt);

  @override
  TemplateDbModel lastSavedDeviceId(String? lastSavedDeviceId) =>
      call(lastSavedDeviceId: lastSavedDeviceId);

  @override
  TemplateDbModel permanentlyDeletedAt(DateTime? permanentlyDeletedAt) =>
      call(permanentlyDeletedAt: permanentlyDeletedAt);

  @override
  TemplateDbModel index(int? index) => call(index: index);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TemplateDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  TemplateDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
    Object? galleryTemplateId = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? preferences = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? archivedAt = const $CopyWithPlaceholder(),
    Object? lastSavedDeviceId = const $CopyWithPlaceholder(),
    Object? permanentlyDeletedAt = const $CopyWithPlaceholder(),
    Object? index = const $CopyWithPlaceholder(),
  }) {
    return TemplateDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<int>?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as StoryContentDbModel?,
      galleryTemplateId: galleryTemplateId == const $CopyWithPlaceholder()
          ? _value.galleryTemplateId
          // ignore: cast_nullable_to_non_nullable
          : galleryTemplateId as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      preferences: preferences == const $CopyWithPlaceholder()
          ? _value.preferences
          // ignore: cast_nullable_to_non_nullable
          : preferences as StoryPreferencesDbModel?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      archivedAt: archivedAt == const $CopyWithPlaceholder()
          ? _value.archivedAt
          // ignore: cast_nullable_to_non_nullable
          : archivedAt as DateTime?,
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTemplateDbModel.copyWith(...)` or `instanceOfTemplateDbModel.copyWith.fieldName(...)`.
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
      name: json['name'] as String?,
      content: json['content'] == null
          ? null
          : StoryContentDbModel.fromJson(
              json['content'] as Map<String, dynamic>,
            ),
      galleryTemplateId: json['gallery_template_id'] as String?,
      note: json['note'] as String?,
      preferences: json['preferences'] == null
          ? null
          : StoryPreferencesDbModel.fromJson(
              json['preferences'] as Map<String, dynamic>,
            ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      lastSavedDeviceId: json['last_saved_device_id'] as String?,
      permanentlyDeletedAt: json['permanently_deleted_at'] == null
          ? null
          : DateTime.parse(json['permanently_deleted_at'] as String),
      index: (json['index'] as num?)?.toInt(),
    )..storiesCount = (json['stories_count'] as num?)?.toInt();

Map<String, dynamic> _$TemplateDbModelToJson(
  TemplateDbModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'tags': instance.tags,
  'preferences': instance.preferences.toJson(),
  'name': instance.name,
  'content': instance.content?.toJson(),
  'gallery_template_id': instance.galleryTemplateId,
  'note': instance.note,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'last_saved_device_id': instance.lastSavedDeviceId,
  'archived_at': instance.archivedAt?.toIso8601String(),
  'permanently_deleted_at': instance.permanentlyDeletedAt?.toIso8601String(),
  'stories_count': instance.storiesCount,
};
