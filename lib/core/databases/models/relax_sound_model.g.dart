// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relax_sound_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelaxSoundModelCWProxy {
  RelaxSoundModel soundUrlPath(String soundUrlPath);

  RelaxSoundModel volume(double volume);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `RelaxSoundModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelaxSoundModel(...).copyWith(id: 12, name: "My name")
  /// ```
  RelaxSoundModel call({String soundUrlPath, double volume});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRelaxSoundModel.copyWith(...)` or call `instanceOfRelaxSoundModel.copyWith.fieldName(value)` for a single field.
class _$RelaxSoundModelCWProxyImpl implements _$RelaxSoundModelCWProxy {
  const _$RelaxSoundModelCWProxyImpl(this._value);

  final RelaxSoundModel _value;

  @override
  RelaxSoundModel soundUrlPath(String soundUrlPath) =>
      call(soundUrlPath: soundUrlPath);

  @override
  RelaxSoundModel volume(double volume) => call(volume: volume);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `RelaxSoundModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelaxSoundModel(...).copyWith(id: 12, name: "My name")
  /// ```
  RelaxSoundModel call({
    Object? soundUrlPath = const $CopyWithPlaceholder(),
    Object? volume = const $CopyWithPlaceholder(),
  }) {
    return RelaxSoundModel(
      soundUrlPath:
          soundUrlPath == const $CopyWithPlaceholder() || soundUrlPath == null
          ? _value.soundUrlPath
          // ignore: cast_nullable_to_non_nullable
          : soundUrlPath as String,
      volume: volume == const $CopyWithPlaceholder() || volume == null
          ? _value.volume
          // ignore: cast_nullable_to_non_nullable
          : volume as double,
    );
  }
}

extension $RelaxSoundModelCopyWith on RelaxSoundModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRelaxSoundModel.copyWith(...)` or `instanceOfRelaxSoundModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelaxSoundModelCWProxy get copyWith => _$RelaxSoundModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelaxSoundModel _$RelaxSoundModelFromJson(Map<String, dynamic> json) =>
    RelaxSoundModel(
      soundUrlPath: json['sound_url_path'] as String,
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$RelaxSoundModelToJson(RelaxSoundModel instance) =>
    <String, dynamic>{
      'sound_url_path': instance.soundUrlPath,
      'volume': instance.volume,
    };
