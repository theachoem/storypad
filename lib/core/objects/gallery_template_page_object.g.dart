// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_template_page_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryTemplatePageObjectCWProxy {
  GalleryTemplatePageObject title(String title);

  GalleryTemplatePageObject content(String content);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GalleryTemplatePageObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryTemplatePageObject(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryTemplatePageObject call({String title, String content});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryTemplatePageObject.copyWith(...)` or call `instanceOfGalleryTemplatePageObject.copyWith.fieldName(value)` for a single field.
class _$GalleryTemplatePageObjectCWProxyImpl
    implements _$GalleryTemplatePageObjectCWProxy {
  const _$GalleryTemplatePageObjectCWProxyImpl(this._value);

  final GalleryTemplatePageObject _value;

  @override
  GalleryTemplatePageObject title(String title) => call(title: title);

  @override
  GalleryTemplatePageObject content(String content) => call(content: content);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GalleryTemplatePageObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryTemplatePageObject(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryTemplatePageObject call({
    Object? title = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return GalleryTemplatePageObject(
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
    );
  }
}

extension $GalleryTemplatePageObjectCopyWith on GalleryTemplatePageObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryTemplatePageObject.copyWith(...)` or `instanceOfGalleryTemplatePageObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryTemplatePageObjectCWProxy get copyWith =>
      _$GalleryTemplatePageObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryTemplatePageObject _$GalleryTemplatePageObjectFromJson(
  Map<String, dynamic> json,
) => GalleryTemplatePageObject(
  title: json['title'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$GalleryTemplatePageObjectToJson(
  GalleryTemplatePageObject instance,
) => <String, dynamic>{'title': instance.title, 'content': instance.content};
