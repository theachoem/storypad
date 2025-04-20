// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relax_sound_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelaxSoundObjectCWProxy {
  RelaxSoundObject translationKey(String translationKey);

  RelaxSoundObject svgIconUrlPath(String svgIconUrlPath);

  RelaxSoundObject soundUrlPath(String soundUrlPath);

  RelaxSoundObject dayColor(int dayColor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundObject(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundObject call({
    String translationKey,
    String svgIconUrlPath,
    String soundUrlPath,
    int dayColor,
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
  RelaxSoundObject svgIconUrlPath(String svgIconUrlPath) =>
      this(svgIconUrlPath: svgIconUrlPath);

  @override
  RelaxSoundObject soundUrlPath(String soundUrlPath) =>
      this(soundUrlPath: soundUrlPath);

  @override
  RelaxSoundObject dayColor(int dayColor) => this(dayColor: dayColor);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundObject(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundObject call({
    Object? translationKey = const $CopyWithPlaceholder(),
    Object? svgIconUrlPath = const $CopyWithPlaceholder(),
    Object? soundUrlPath = const $CopyWithPlaceholder(),
    Object? dayColor = const $CopyWithPlaceholder(),
  }) {
    return RelaxSoundObject(
      translationKey: translationKey == const $CopyWithPlaceholder()
          ? _value.translationKey
          // ignore: cast_nullable_to_non_nullable
          : translationKey as String,
      svgIconUrlPath: svgIconUrlPath == const $CopyWithPlaceholder()
          ? _value.svgIconUrlPath
          // ignore: cast_nullable_to_non_nullable
          : svgIconUrlPath as String,
      soundUrlPath: soundUrlPath == const $CopyWithPlaceholder()
          ? _value.soundUrlPath
          // ignore: cast_nullable_to_non_nullable
          : soundUrlPath as String,
      dayColor: dayColor == const $CopyWithPlaceholder()
          ? _value.dayColor
          // ignore: cast_nullable_to_non_nullable
          : dayColor as int,
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
      svgIconUrlPath: json['svg_icon_url_path'] as String,
      soundUrlPath: json['sound_url_path'] as String,
      dayColor: (json['day_color'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$RelaxSoundObjectToJson(RelaxSoundObject instance) =>
    <String, dynamic>{
      'translation_key': instance.translationKey,
      'svg_icon_url_path': instance.svgIconUrlPath,
      'sound_url_path': instance.soundUrlPath,
      'day_color': instance.dayColor,
    };
