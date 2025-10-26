// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_template_category.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryTemplateCategoryObjectCWProxy {
  GalleryTemplateCategoryObject name(String name);

  GalleryTemplateCategoryObject description(String description);

  GalleryTemplateCategoryObject templates(
    List<GalleryTemplateObject> templates,
  );

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GalleryTemplateCategoryObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryTemplateCategoryObject(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryTemplateCategoryObject call({
    String name,
    String description,
    List<GalleryTemplateObject> templates,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryTemplateCategoryObject.copyWith(...)` or call `instanceOfGalleryTemplateCategoryObject.copyWith.fieldName(value)` for a single field.
class _$GalleryTemplateCategoryObjectCWProxyImpl
    implements _$GalleryTemplateCategoryObjectCWProxy {
  const _$GalleryTemplateCategoryObjectCWProxyImpl(this._value);

  final GalleryTemplateCategoryObject _value;

  @override
  GalleryTemplateCategoryObject name(String name) => call(name: name);

  @override
  GalleryTemplateCategoryObject description(String description) =>
      call(description: description);

  @override
  GalleryTemplateCategoryObject templates(
    List<GalleryTemplateObject> templates,
  ) => call(templates: templates);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GalleryTemplateCategoryObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryTemplateCategoryObject(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryTemplateCategoryObject call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? templates = const $CopyWithPlaceholder(),
  }) {
    return GalleryTemplateCategoryObject(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      templates: templates == const $CopyWithPlaceholder() || templates == null
          ? _value.templates
          // ignore: cast_nullable_to_non_nullable
          : templates as List<GalleryTemplateObject>,
    );
  }
}

extension $GalleryTemplateCategoryObjectCopyWith
    on GalleryTemplateCategoryObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryTemplateCategoryObject.copyWith(...)` or `instanceOfGalleryTemplateCategoryObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryTemplateCategoryObjectCWProxy get copyWith =>
      _$GalleryTemplateCategoryObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryTemplateCategoryObject _$GalleryTemplateCategoryObjectFromJson(
  Map<String, dynamic> json,
) => GalleryTemplateCategoryObject(
  name: json['name'] as String,
  description: json['description'] as String,
  templates: (json['templates'] as List<dynamic>)
      .map((e) => GalleryTemplateObject.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GalleryTemplateCategoryObjectToJson(
  GalleryTemplateCategoryObject instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'templates': instance.templates.map((e) => e.toJson()).toList(),
};
