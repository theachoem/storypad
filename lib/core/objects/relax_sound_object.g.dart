// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relax_sound_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelaxSoundObjectCWProxy {
  RelaxSoundObject translationKey(String translationKey);

  RelaxSoundObject svgIconPath(String svgIconPath);

  RelaxSoundObject soundPath(String soundPath);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundObject(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundObject call({
    String translationKey,
    String svgIconPath,
    String soundPath,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRelaxSoundObject.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRelaxSoundObject.copyWith.fieldName(...)`
class _$RelaxSoundObjectCWProxyImpl implements _$RelaxSoundObjectCWProxy {
  const _$RelaxSoundObjectCWProxyImpl(this._value);

  final RelaxSoundObject _value;

  @override
  RelaxSoundObject translationKey(String translationKey) =>
      this(translationKey: translationKey);

  @override
  RelaxSoundObject svgIconPath(String svgIconPath) =>
      this(svgIconPath: svgIconPath);

  @override
  RelaxSoundObject soundPath(String soundPath) => this(soundPath: soundPath);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundObject(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundObject call({
    Object? translationKey = const $CopyWithPlaceholder(),
    Object? svgIconPath = const $CopyWithPlaceholder(),
    Object? soundPath = const $CopyWithPlaceholder(),
  }) {
    return RelaxSoundObject(
      translationKey: translationKey == const $CopyWithPlaceholder()
          ? _value.translationKey
          // ignore: cast_nullable_to_non_nullable
          : translationKey as String,
      svgIconPath: svgIconPath == const $CopyWithPlaceholder()
          ? _value.svgIconPath
          // ignore: cast_nullable_to_non_nullable
          : svgIconPath as String,
      soundPath: soundPath == const $CopyWithPlaceholder()
          ? _value.soundPath
          // ignore: cast_nullable_to_non_nullable
          : soundPath as String,
    );
  }
}

extension $RelaxSoundObjectCopyWith on RelaxSoundObject {
  /// Returns a callable class that can be used as follows: `instanceOfRelaxSoundObject.copyWith(...)` or like so:`instanceOfRelaxSoundObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelaxSoundObjectCWProxy get copyWith => _$RelaxSoundObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelaxSoundObject _$RelaxSoundObjectFromJson(Map<String, dynamic> json) =>
    RelaxSoundObject(
      translationKey: json['translation_key'] as String,
      svgIconPath: json['svg_icon_path'] as String,
      soundPath: json['sound_path'] as String,
    );

Map<String, dynamic> _$RelaxSoundObjectToJson(RelaxSoundObject instance) =>
    <String, dynamic>{
      'translation_key': instance.translationKey,
      'svg_icon_path': instance.svgIconPath,
      'sound_path': instance.soundPath,
    };
