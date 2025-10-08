// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relax_sound_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelaxSoundObjectCWProxy {
  RelaxSoundObject artist(String artist);

  RelaxSoundObject translationKey(String translationKey);

  RelaxSoundObject svgIconUrlPath(String svgIconUrlPath);

  RelaxSoundObject background(FirestoreStorageBackground background);

  RelaxSoundObject soundUrlPath(String soundUrlPath);

  RelaxSoundObject dayColor(int dayColor);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `RelaxSoundObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelaxSoundObject(...).copyWith(id: 12, name: "My name")
  /// ```
  RelaxSoundObject call({
    String artist,
    String translationKey,
    String svgIconUrlPath,
    FirestoreStorageBackground background,
    String soundUrlPath,
    int dayColor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRelaxSoundObject.copyWith(...)` or call `instanceOfRelaxSoundObject.copyWith.fieldName(value)` for a single field.
class _$RelaxSoundObjectCWProxyImpl implements _$RelaxSoundObjectCWProxy {
  const _$RelaxSoundObjectCWProxyImpl(this._value);

  final RelaxSoundObject _value;

  @override
  RelaxSoundObject artist(String artist) => call(artist: artist);

  @override
  RelaxSoundObject translationKey(String translationKey) =>
      call(translationKey: translationKey);

  @override
  RelaxSoundObject svgIconUrlPath(String svgIconUrlPath) =>
      call(svgIconUrlPath: svgIconUrlPath);

  @override
  RelaxSoundObject background(FirestoreStorageBackground background) =>
      call(background: background);

  @override
  RelaxSoundObject soundUrlPath(String soundUrlPath) =>
      call(soundUrlPath: soundUrlPath);

  @override
  RelaxSoundObject dayColor(int dayColor) => call(dayColor: dayColor);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `RelaxSoundObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RelaxSoundObject(...).copyWith(id: 12, name: "My name")
  /// ```
  RelaxSoundObject call({
    Object? artist = const $CopyWithPlaceholder(),
    Object? translationKey = const $CopyWithPlaceholder(),
    Object? svgIconUrlPath = const $CopyWithPlaceholder(),
    Object? background = const $CopyWithPlaceholder(),
    Object? soundUrlPath = const $CopyWithPlaceholder(),
    Object? dayColor = const $CopyWithPlaceholder(),
  }) {
    return RelaxSoundObject(
      artist: artist == const $CopyWithPlaceholder() || artist == null
          ? _value.artist
          // ignore: cast_nullable_to_non_nullable
          : artist as String,
      translationKey:
          translationKey == const $CopyWithPlaceholder() ||
              translationKey == null
          ? _value.translationKey
          // ignore: cast_nullable_to_non_nullable
          : translationKey as String,
      svgIconUrlPath:
          svgIconUrlPath == const $CopyWithPlaceholder() ||
              svgIconUrlPath == null
          ? _value.svgIconUrlPath
          // ignore: cast_nullable_to_non_nullable
          : svgIconUrlPath as String,
      background:
          background == const $CopyWithPlaceholder() || background == null
          ? _value.background
          // ignore: cast_nullable_to_non_nullable
          : background as FirestoreStorageBackground,
      soundUrlPath:
          soundUrlPath == const $CopyWithPlaceholder() || soundUrlPath == null
          ? _value.soundUrlPath
          // ignore: cast_nullable_to_non_nullable
          : soundUrlPath as String,
      dayColor: dayColor == const $CopyWithPlaceholder() || dayColor == null
          ? _value.dayColor
          // ignore: cast_nullable_to_non_nullable
          : dayColor as int,
    );
  }
}

extension $RelaxSoundObjectCopyWith on RelaxSoundObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRelaxSoundObject.copyWith(...)` or `instanceOfRelaxSoundObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelaxSoundObjectCWProxy get copyWith => _$RelaxSoundObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelaxSoundObject _$RelaxSoundObjectFromJson(Map<String, dynamic> json) =>
    RelaxSoundObject(
      artist: json['artist'] as String,
      translationKey: json['translation_key'] as String,
      svgIconUrlPath: json['svg_icon_url_path'] as String,
      background: $enumDecode(
        _$FirestoreStorageBackgroundEnumMap,
        json['background'],
      ),
      soundUrlPath: json['sound_url_path'] as String,
      dayColor: (json['day_color'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$RelaxSoundObjectToJson(RelaxSoundObject instance) =>
    <String, dynamic>{
      'translation_key': instance.translationKey,
      'artist': instance.artist,
      'svg_icon_url_path': instance.svgIconUrlPath,
      'background': _$FirestoreStorageBackgroundEnumMap[instance.background]!,
      'sound_url_path': instance.soundUrlPath,
      'day_color': instance.dayColor,
    };

const _$FirestoreStorageBackgroundEnumMap = {
  FirestoreStorageBackground.abstract_water_drops_on_turquoise_glass_background:
      'abstract_water_drops_on_turquoise_glass_background',
  FirestoreStorageBackground.color_beautiful_sky_vintage_forest:
      'color_beautiful_sky_vintage_forest',
  FirestoreStorageBackground.cups_and_pot_near_fire: 'cups_and_pot_near_fire',
  FirestoreStorageBackground.designer_at_work_in_office:
      'designer_at_work_in_office',
  FirestoreStorageBackground.fall_leaves_hanging_on_blurry_surface:
      'fall_leaves_hanging_on_blurry_surface',
  FirestoreStorageBackground.forest_full_of_high_rise_trees:
      'forest_full_of_high_rise_trees',
  FirestoreStorageBackground.music_notes_on_heart_shaped_paper:
      'music_notes_on_heart_shaped_paper',
  FirestoreStorageBackground
          .textured_green_and_black_liquefy_abstract_background:
      'textured_green_and_black_liquefy_abstract_background',
  FirestoreStorageBackground.two_cloudy_tags_on_color_background:
      'two_cloudy_tags_on_color_background',
};
