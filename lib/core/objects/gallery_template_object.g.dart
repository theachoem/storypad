// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_template_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryTemplateObjectCWProxy {
  GalleryTemplateObject id(String id);

  GalleryTemplateObject name(String name);

  GalleryTemplateObject purpose(String purpose);

  GalleryTemplateObject note(String? note);

  GalleryTemplateObject pages(List<GalleryTemplatePageObject> pages);

  GalleryTemplateObject iconUrlPath(String iconUrlPath);

  GalleryTemplateObject lazyDraftContent(StoryContentDbModel? lazyDraftContent);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GalleryTemplateObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryTemplateObject(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryTemplateObject call({
    String id,
    String name,
    String purpose,
    String? note,
    List<GalleryTemplatePageObject> pages,
    String iconUrlPath,
    StoryContentDbModel? lazyDraftContent,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryTemplateObject.copyWith(...)` or call `instanceOfGalleryTemplateObject.copyWith.fieldName(value)` for a single field.
class _$GalleryTemplateObjectCWProxyImpl
    implements _$GalleryTemplateObjectCWProxy {
  const _$GalleryTemplateObjectCWProxyImpl(this._value);

  final GalleryTemplateObject _value;

  @override
  GalleryTemplateObject id(String id) => call(id: id);

  @override
  GalleryTemplateObject name(String name) => call(name: name);

  @override
  GalleryTemplateObject purpose(String purpose) => call(purpose: purpose);

  @override
  GalleryTemplateObject note(String? note) => call(note: note);

  @override
  GalleryTemplateObject pages(List<GalleryTemplatePageObject> pages) =>
      call(pages: pages);

  @override
  GalleryTemplateObject iconUrlPath(String iconUrlPath) =>
      call(iconUrlPath: iconUrlPath);

  @override
  GalleryTemplateObject lazyDraftContent(
    StoryContentDbModel? lazyDraftContent,
  ) => call(lazyDraftContent: lazyDraftContent);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GalleryTemplateObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryTemplateObject(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryTemplateObject call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? pages = const $CopyWithPlaceholder(),
    Object? iconUrlPath = const $CopyWithPlaceholder(),
    Object? lazyDraftContent = const $CopyWithPlaceholder(),
  }) {
    return GalleryTemplateObject(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      purpose: purpose == const $CopyWithPlaceholder() || purpose == null
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as String,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      pages: pages == const $CopyWithPlaceholder() || pages == null
          ? _value.pages
          // ignore: cast_nullable_to_non_nullable
          : pages as List<GalleryTemplatePageObject>,
      iconUrlPath:
          iconUrlPath == const $CopyWithPlaceholder() || iconUrlPath == null
          ? _value.iconUrlPath
          // ignore: cast_nullable_to_non_nullable
          : iconUrlPath as String,
      lazyDraftContent: lazyDraftContent == const $CopyWithPlaceholder()
          ? _value.lazyDraftContent
          // ignore: cast_nullable_to_non_nullable
          : lazyDraftContent as StoryContentDbModel?,
    );
  }
}

extension $GalleryTemplateObjectCopyWith on GalleryTemplateObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryTemplateObject.copyWith(...)` or `instanceOfGalleryTemplateObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryTemplateObjectCWProxy get copyWith =>
      _$GalleryTemplateObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryTemplateObject _$GalleryTemplateObjectFromJson(
  Map<String, dynamic> json,
) => GalleryTemplateObject(
  id: json['id'] as String,
  name: json['name'] as String,
  purpose: json['purpose'] as String,
  note: json['note'] as String?,
  pages: (json['pages'] as List<dynamic>)
      .map((e) => GalleryTemplatePageObject.fromJson(e as Map<String, dynamic>))
      .toList(),
  iconUrlPath: json['icon_url_path'] as String,
  lazyDraftContent: json['lazy_draft_content'] == null
      ? null
      : StoryContentDbModel.fromJson(
          json['lazy_draft_content'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$GalleryTemplateObjectToJson(
  GalleryTemplateObject instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'purpose': instance.purpose,
  'note': instance.note,
  'pages': instance.pages.map((e) => e.toJson()).toList(),
  'icon_url_path': instance.iconUrlPath,
  'lazy_draft_content': instance.lazyDraftContent?.toJson(),
};
