// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relax_sound_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelaxSoundModelCWProxy {
  RelaxSoundModel soundUrlPath(String soundUrlPath);

  RelaxSoundModel volume(double volume);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundModel(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundModel call({
    String soundUrlPath,
    double volume,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRelaxSoundModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRelaxSoundModel.copyWith.fieldName(...)`
class _$RelaxSoundModelCWProxyImpl implements _$RelaxSoundModelCWProxy {
  const _$RelaxSoundModelCWProxyImpl(this._value);

  final RelaxSoundModel _value;

  @override
  RelaxSoundModel soundUrlPath(String soundUrlPath) =>
      this(soundUrlPath: soundUrlPath);

  @override
  RelaxSoundModel volume(double volume) => this(volume: volume);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelaxSoundModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelaxSoundModel(...).copyWith(id: 12, name: "My name")
  /// ````
  RelaxSoundModel call({
    Object? soundUrlPath = const $CopyWithPlaceholder(),
    Object? volume = const $CopyWithPlaceholder(),
  }) {
    return RelaxSoundModel(
      soundUrlPath: soundUrlPath == const $CopyWithPlaceholder()
          ? _value.soundUrlPath
          // ignore: cast_nullable_to_non_nullable
          : soundUrlPath as String,
      volume: volume == const $CopyWithPlaceholder()
          ? _value.volume
          // ignore: cast_nullable_to_non_nullable
          : volume as double,
    );
  }
}

extension $RelaxSoundModelCopyWith on RelaxSoundModel {
  /// Returns a callable class that can be used as follows: `instanceOfRelaxSoundModel.copyWith(...)` or like so:`instanceOfRelaxSoundModel.copyWith.fieldName(...)`.
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
